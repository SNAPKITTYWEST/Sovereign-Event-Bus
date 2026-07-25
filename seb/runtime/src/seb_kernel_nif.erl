%%%-------------------------------------------------------------------
%% @doc Sovereign Event Bus — Ada/C Kernel NIF Bridge
%%
%% Loads seb_kernel_nif.so (built from seb_kernel_nif.c + seb_lattice.c).
%% Once loaded, Erlang replaces the stub bodies below with C dispatch.
%%
%% L0 Invariants enforced by the C kernel on every append_event:
%%   1. Commitment chain: circuit(prev_tip || header64) == footer.commitment
%%   2. Hash chain: footer.prev_commitment == tip
%%   3. Offset monotonic: new_offset > tip_offset
%%   4. Segment bounds: event fits in 1 GiB segment
%%   5. Sequence monotonic on rotate
%%
%% Authority and signature are handled upstream by seb_datalog_bridge
%% before events reach this module. The kernel enforces structure only.
%% @end
%%%-------------------------------------------------------------------
-module(seb_kernel_nif).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
    init_kernel/2,       %% (SegmentId, SegmentSequence) -> {ok, Handle} | {error, Reason}
    append_event/4,      %% (Handle, Header, Payload, Footer) -> {ok, Offset} | {error, Reason}
    rotate_segment/3,    %% (Handle, NewSegmentId, NewSequence) -> {ok, 0} | {error, Reason}
    verify_chain/1,      %% (Handle) -> {ok, EventsSealed} | {error, Reason}
    commit_offset/4,     %% (Handle, AgentId, Partition, Offset) -> ok
    get_state/1          %% (Handle) -> {SegId, Seq, Sealed, Rotated, TipOffset}
]).

-define(SERVER, ?MODULE).
-define(NIF_LIB, "seb_kernel_nif").

-record(state, {handle}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

-spec init_kernel(non_neg_integer(), non_neg_integer()) ->
    {ok, reference()} | {error, term()}.
init_kernel(SegmentId, SegmentSequence) ->
    gen_server:call(?SERVER, {init_kernel, SegmentId, SegmentSequence}).

-spec append_event(reference(), binary(), binary(), binary()) ->
    {ok, non_neg_integer()} | {error, term()}.
append_event(Handle, Header, Payload, Footer) ->
    gen_server:call(?SERVER, {append_event, Handle, Header, Payload, Footer}).

-spec rotate_segment(reference(), non_neg_integer(), non_neg_integer()) ->
    {ok, 0} | {error, term()}.
rotate_segment(Handle, NewSegmentId, NewSequence) ->
    gen_server:call(?SERVER, {rotate_segment, Handle, NewSegmentId, NewSequence}).

-spec verify_chain(reference()) -> {ok, non_neg_integer()} | {error, term()}.
verify_chain(Handle) ->
    gen_server:call(?SERVER, {verify_chain, Handle}).

-spec commit_offset(reference(), non_neg_integer(), non_neg_integer(), non_neg_integer()) -> ok.
commit_offset(Handle, AgentId, Partition, Offset) ->
    gen_server:call(?SERVER, {commit_offset, Handle, AgentId, Partition, Offset}).

-spec get_state(reference()) ->
    {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}.
get_state(Handle) ->
    gen_server:call(?SERVER, {get_state, Handle}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    SoPath = filename:join([code:priv_dir(seb), ?NIF_LIB]),
    case erlang:load_nif(SoPath, []) of
        ok ->
            {ok, Handle} = nif_init_kernel(0, 0),
            {ok, #state{handle = Handle}};
        {error, {reload, _}} ->
            %% already loaded (hot-reload path)
            {ok, Handle} = nif_init_kernel(0, 0),
            {ok, #state{handle = Handle}};
        {error, Reason} ->
            {stop, {nif_load_failed, SoPath, Reason}}
    end.

handle_call({init_kernel, SegId, Seq}, _From, State) ->
    {reply, nif_init_kernel(SegId, Seq), State};

handle_call({append_event, Handle, Header, Payload, Footer}, _From, State) ->
    {reply, nif_append_event(Handle, Header, Payload, Footer), State};

handle_call({rotate_segment, Handle, NewId, NewSeq}, _From, State) ->
    {reply, nif_rotate_segment(Handle, NewId, NewSeq), State};

handle_call({verify_chain, Handle}, _From, State) ->
    {reply, nif_verify_chain(Handle), State};

handle_call({commit_offset, Handle, AgentId, Partition, Offset}, _From, State) ->
    {reply, nif_commit_offset(Handle, AgentId, Partition, Offset), State};

handle_call({get_state, Handle}, _From, State) ->
    {reply, nif_get_state(Handle), State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%%===================================================================
%%% NIF stubs — replaced by C dispatch after load_nif succeeds
%%%===================================================================

nif_init_kernel(_SegmentId, _SegmentSequence) ->
    erlang:nif_error(nif_not_loaded).

nif_append_event(_Handle, _Header, _Payload, _Footer) ->
    erlang:nif_error(nif_not_loaded).

nif_rotate_segment(_Handle, _NewSegmentId, _NewSequence) ->
    erlang:nif_error(nif_not_loaded).

nif_verify_chain(_Handle) ->
    erlang:nif_error(nif_not_loaded).

nif_commit_offset(_Handle, _AgentId, _Partition, _Offset) ->
    erlang:nif_error(nif_not_loaded).

nif_get_state(_Handle) ->
    erlang:nif_error(nif_not_loaded).
