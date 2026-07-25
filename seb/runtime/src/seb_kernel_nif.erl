%%%-------------------------------------------------------------------
%% @doc Sovereign Event Bus - Ada Kernel NIF Bridge
%%
%% NIF (Native Interface Function) wrapper for Ada kernel (seb_kernel.adb)
%% Per XML L2 spec, implements:
%%   - append_event: Append event with cryptographic verification
%%   - commit_offset: Commit offset to WAL
%%   - verify_chain: Verify entire event chain integrity
%%
%% L0 Invariants enforced by kernel:
%%   1. Plasma Gate: Ed25519 signature valid
%%   2. Hash Chain: Prev_Hash == current tip hash
%%   3. Offset Monotonic: Event offset > prior offset
%%   4. Payload Hash: blake3(header || payload) matches footer
%%   5. Segment Chain: Prev_Seg_Hash links to prior segment
%%
%% @end
%%%-------------------------------------------------------------------
-module(seb_kernel_nif).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% NIF API
-export([
    append_event/4,      %% (Header, Payload, Footer) -> {ok, Offset} | {error, Reason}
    commit_offset/1,     %% (Offset) -> ok | {error, Reason}
    verify_chain/0,      %% () -> {ok, Count} | {error, Reason}
    get_tip_hash/0       %% () -> {ok, Hash} | {error, Reason}
]).

-define(SERVER, ?MODULE).
-define(NIF_LIBRARY, "libseb_kernel").
-define(NIF_LOAD_TIMEOUT, 5000).

-record(state, {
    kernel_loaded :: boolean(),
    nif_module :: atom()
}).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Start the NIF bridge
-spec start_link() -> gen_server:start_ret().
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% @doc Append an event to the kernel
%%
%% Header: Binary containing event header (68 bytes)
%% Payload: Binary event data
%% Footer: Binary containing event footer (128 bytes) with signature/hash
%%
%% Returns: {ok, CommittedOffset} | {error, Reason}
%%
%% Pre-conditions checked by kernel:
%%   1. Ed25519 signature valid on event hash
%%   2. Prev_Hash matches current state tip hash
%%   3. Payload size <= Max_Payload_Size
%%
-spec append_event(binary(), binary(), binary(), binary()) -> {ok, non_neg_integer()} | {error, term()}.
append_event(Header, Payload, Footer, PublicKey) when
    is_binary(Header),
    is_binary(Payload),
    is_binary(Footer),
    is_binary(PublicKey)
->
    gen_server:call(?SERVER, {append_event, Header, Payload, Footer, PublicKey}).

%% @doc Commit an offset to the kernel WAL
%%
%% Offset: Event offset to commit (must be monotonically increasing)
%%
%% Returns: ok | {error, Reason}
%%
%% The kernel verifies:
%%   1. Offset > previous committed offset
%%   2. Offset corresponds to a valid event
%%
-spec commit_offset(non_neg_integer()) -> ok | {error, term()}.
commit_offset(Offset) when is_integer(Offset), Offset >= 0 ->
    gen_server:call(?SERVER, {commit_offset, Offset}).

%% @doc Verify entire event chain integrity
%%
%% Traverses from tip to genesis, verifying:
%%   1. Hash chain validity
%%   2. Signature validity
%%   3. Offset monotonicity
%%
%% Returns: {ok, VerifiedCount} | {error, Reason}
%%
-spec verify_chain() -> {ok, non_neg_integer()} | {error, term()}.
verify_chain() ->
    gen_server:call(?SERVER, verify_chain).

%% @doc Get current tip hash
%%
%% Returns hash of the most recent event in the chain
%%
-spec get_tip_hash() -> {ok, binary()} | {error, term()}.
get_tip_hash() ->
    gen_server:call(?SERVER, get_tip_hash).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%% @doc Initialize the NIF bridge
%%
%% Attempts to load the native library (libseb_kernel).
%% If loading fails, the server exits with fatal error.
%%
-spec init([]) -> {ok, #state{}} | {stop, term()}.
init([]) ->
    case load_nif_library() of
        ok ->
            State = #state{
                kernel_loaded = true,
                nif_module = ?MODULE
            },
            {ok, State};
        {error, Reason} ->
            {stop, {nif_load_failed, Reason}}
    end.

%% @doc Handle synchronous calls
-spec handle_call(term(), {pid(), term()}, #state{}) -> {reply, term(), #state{}}.

handle_call({append_event, Header, Payload, Footer, PublicKey}, _From, State) ->
    Result = append_event_nif(Header, Payload, Footer, PublicKey),
    {reply, Result, State};

handle_call({commit_offset, Offset}, _From, State) ->
    Result = commit_offset_nif(Offset),
    {reply, Result, State};

handle_call(verify_chain, _From, State) ->
    Result = verify_chain_nif(),
    {reply, Result, State};

handle_call(get_tip_hash, _From, State) ->
    Result = get_tip_hash_nif(),
    {reply, Result, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

%% @doc Handle asynchronous casts
-spec handle_cast(term(), #state{}) -> {noreply, #state{}}.
handle_cast(_Msg, State) ->
    {noreply, State}.

%% @doc Handle info messages
-spec handle_info(term(), #state{}) -> {noreply, #state{}}.
handle_info(_Info, State) ->
    {noreply, State}.

%% @doc Terminate the NIF bridge
-spec terminate(term(), #state{}) -> ok.
terminate(_Reason, _State) ->
    ok.

%% @doc Code change (upgrade support)
-spec code_change(term(), #state{}, term()) -> {ok, #state{}}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% NIF Stub Functions (actual implementation in C)
%%%===================================================================

%% @doc Load the native library
%%
%% In a real implementation, this would call:
%%   erl_nif:load_nif(?NIF_LIBRARY, ...)
%%
%% For now, returns ok (test stub)
%%
-spec load_nif_library() -> ok | {error, term()}.
load_nif_library() ->
    try
        %% Real implementation:
        %% erlang:load_nif(filename:join([code:priv_dir(seb), ?NIF_LIBRARY]), [])
        %% For test: return ok
        ok
    catch
        _Type:_Reason ->
            {error, nif_load_failed}
    end.

%% @doc NIF stub: append_event
%%
%% This should call into C code that:
%%   1. Verifies Ed25519 signature
%%   2. Checks hash chain validity
%%   3. Appends to WAL
%%   4. Returns committed offset
%%
-spec append_event_nif(binary(), binary(), binary(), binary()) ->
    {ok, non_neg_integer()} | {error, term()}.
append_event_nif(_Header, _Payload, _Footer, _PublicKey) ->
    %% TODO: Replace with actual NIF call
    {error, nif_not_implemented}.

%% @doc NIF stub: commit_offset
%%
%% This should call into C code that:
%%   1. Verifies offset monotonicity
%%   2. Commits offset to WAL
%%   3. Calls msync for durability
%%
-spec commit_offset_nif(non_neg_integer()) -> ok | {error, term()}.
commit_offset_nif(_Offset) ->
    %% TODO: Replace with actual NIF call
    ok.

%% @doc NIF stub: verify_chain
%%
%% This should call into C code that:
%%   1. Traverses event chain from tip to genesis
%%   2. Verifies each event's signature and hash
%%   3. Returns count of verified events
%%
-spec verify_chain_nif() -> {ok, non_neg_integer()} | {error, term()}.
verify_chain_nif() ->
    %% TODO: Replace with actual NIF call
    {error, nif_not_implemented}.

%% @doc NIF stub: get_tip_hash
%%
%% This should call into C code that:
%%   1. Returns the hash of the most recent event
%%
-spec get_tip_hash_nif() -> {ok, binary()} | {error, term()}.
get_tip_hash_nif() ->
    %% TODO: Replace with actual NIF call
    {error, nif_not_implemented}.
