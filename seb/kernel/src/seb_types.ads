--  Sovereign Event Bus (SEB) - Type Definitions
--  Ada 2012 / SPARK Level 4
--
--  This file defines canonical wire types matching L0 Idris specification.
--  All types are WORM-sealed with cryptographic verification.
--
--  Wire Layout:
--    Event = 68-byte Header || variable Payload || 128-byte Footer
--    Segment = 64-byte Header || Events || Segment Chain Link
--
--  Constants:
--    Fixed_Header_Size = 68 bytes
--    Fixed_Footer_Size = 128 bytes
--    Segment_Size = 1,073,741,824 bytes (1 GiB)
--    Hash_Size = 32 bytes (BLAKE3)
--    Signature_Size = 64 bytes (Ed25519)

pragma SPARK_Mode (On);

with Ada.Types;
use Ada.Types;

package SEB_Types is
   pragma Pure;

   --  Cryptographic Constants (BLAKE3 = 32 bytes, Ed25519 = 64 bytes)
   Hash_Size_Bytes : constant := 32;
   Signature_Size_Bytes : constant := 64;

   --  Wire Layout Constants
   Fixed_Header_Size : constant := 68;    -- 68-byte event header
   Fixed_Footer_Size : constant := 128;   -- 128-byte event footer
   Segment_Header_Size : constant := 64;  -- 64-byte segment header
   Segment_Size : constant := 1_073_741_824;  -- 1 GiB (2**30 bytes)

   --  Derived Constants
   Event_Min_Size : constant := Fixed_Header_Size + Fixed_Footer_Size;  -- 196 bytes minimum
   Payload_Max_Size : constant := Segment_Size - Fixed_Header_Size - Fixed_Footer_Size - Segment_Header_Size;

   --  Offset Type (within segment)
   type Segment_Offset is new Unsigned_64;
   Min_Offset : constant Segment_Offset := 0;
   Max_Offset : constant Segment_Offset := Segment_Offset (Segment_Size - 1);

   --  Hash Type (32 bytes for BLAKE3)
   type Hash_Type is array (1 .. Hash_Size_Bytes) of Unsigned_8;
   pragma Pack (Hash_Type);

   --  Signature Type (64 bytes for Ed25519)
   type Signature_Type is array (1 .. Signature_Size_Bytes) of Unsigned_8;
   pragma Pack (Signature_Type);

   --  Public Key Type (32 bytes for Ed25519)
   type Public_Key_Type is array (1 .. 32) of Unsigned_8;
   pragma Pack (Public_Key_Type);

   --  Event Header (68 bytes total)
   --  Layout:
   --    Offset  Size  Field
   --    0       8     event_type_id (uint64)
   --    8       8     timestamp (uint64, Unix nanoseconds)
   --    16      8     agent_id (uint64, agent identifier)
   --    24      4     payload_size (uint32, bytes)
   --    28      4     partition_id (uint32, partition number)
   --    32      8     prev_offset (uint64, prior event offset)
   --    40      8     sequence_no (uint64, monotonic counter)
   --    48      20    reserved (for future use)

   type Event_Header is record
      Event_Type_Id : Unsigned_64;  -- Offset 0
      Timestamp_Ns : Unsigned_64;   -- Offset 8, Unix nanoseconds
      Agent_Id : Unsigned_64;       -- Offset 16, agent identifier
      Payload_Size : Unsigned_32;   -- Offset 24, payload bytes
      Partition_Id : Unsigned_32;   -- Offset 28, partition number
      Prev_Offset : Unsigned_64;    -- Offset 32, offset to previous event
      Sequence_No : Unsigned_64;    -- Offset 40, monotonic counter
      Reserved : Unsigned_64;       -- Offset 48, reserved padding
      Reserved2 : Unsigned_32;      -- Offset 56, reserved padding
      Reserved3 : Unsigned_32;      -- Offset 60, reserved padding
   end record;
   pragma Convention (C, Event_Header);
   pragma Pack (Event_Header);
   for Event_Header'Size use Fixed_Header_Size * 8;  -- Exact 68 bytes

   --  Event Footer (128 bytes total)
   --  Layout:
   --    Offset  Size  Field
   --    0       32    prev_hash (BLAKE3 of prior event)
   --    32      32    event_hash (BLAKE3 of header || payload)
   --    64      64    signature (Ed25519 of event_hash)

   type Event_Footer is record
      Prev_Hash : Hash_Type;        -- Offset 0, hash of prior event
      Event_Hash : Hash_Type;       -- Offset 32, hash of header+payload
      Signature : Signature_Type;   -- Offset 64, Ed25519 signature
   end record;
   pragma Convention (C, Event_Footer);
   pragma Pack (Event_Footer);
   for Event_Footer'Size use Fixed_Footer_Size * 8;  -- Exact 128 bytes

   --  Segment Header (64 bytes total)
   --  Layout:
   --    Offset  Size  Field
   --    0       8     segment_id (uint64, globally unique)
   --    8       8     segment_sequence (uint64, monotonic)
   --    16      8     prev_seg_hash (start of hash field)
   --    24      32    prev_seg_hash (complete BLAKE3 of prior segment)
   --    56      8     segment_size (actual size in bytes, <= 1GB)

   type Segment_Header is record
      Segment_Id : Unsigned_64;           -- Offset 0, unique identifier
      Segment_Sequence : Unsigned_64;     -- Offset 8, monotonic counter
      Prev_Seg_Hash : Hash_Type;          -- Offset 16, hash of prior segment
      Segment_Size : Unsigned_64;         -- Offset 48, actual bytes used
   end record;
   pragma Convention (C, Segment_Header);
   pragma Pack (Segment_Header);
   for Segment_Header'Size use Segment_Header_Size * 8;  -- Exact 64 bytes

   --  Event Record (in-memory representation)
   type Event_Record is record
      Header : Event_Header;
      Payload : access Unsigned_8;  -- Pointer to payload data (not part of wire)
      Payload_Size : Unsigned_32;
      Footer : Event_Footer;
   end record;

   --  Kernel State (persistent)
   type Kernel_State is record
      Tip_Hash : Hash_Type;           -- Hash of most recent event
      Tip_Offset : Segment_Offset;    -- Offset within current segment
      Current_Segment_Id : Unsigned_64;
      Events_Sealed : Unsigned_64;    -- Total events cryptographically sealed
      Segments_Rotated : Unsigned_64; -- Total segment rotations
   end record;

   --  Verification Result
   type Verification_Status is (
      Valid,
      Invalid_Signature,
      Invalid_Hash,
      Invalid_Offset,
      Invalid_Sequence,
      Replay_Detected,
      Unknown_Error
   );

   --  Invariant Predicates (SPARK assertions)

   function Is_Valid_Offset (Offset : Segment_Offset) return Boolean is
      (Offset >= Min_Offset and Offset <= Max_Offset);
   pragma Inline (Is_Valid_Offset);

   function Is_Valid_Header (Header : Event_Header) return Boolean is
      (Header.Payload_Size > 0 and
       Header.Payload_Size <= Unsigned_32 (Payload_Max_Size));
   pragma Inline (Is_Valid_Header);

   function Event_Total_Size (Header : Event_Header) return Unsigned_64 is
      (Unsigned_64 (Fixed_Header_Size + Fixed_Footer_Size + Header.Payload_Size));
   pragma Inline (Event_Total_Size);

end SEB_Types;
