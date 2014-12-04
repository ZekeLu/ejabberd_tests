%%%===================================================================
%%% @doc test private mode
%%%===================================================================

-module(privatemode_SUITE).
-compile(export_all).

-include_lib("escalus/include/escalus.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("exml/include/exml_stream.hrl").

-define(WAIT_TIME, 500).
-define(RT_WAIT_TIME, 60000).

-import(metrics_helper, [assert_counter/2,
                         get_counter_value/1]).

%%--------------------------------------------------------------------
%% Suite configuration
%%--------------------------------------------------------------------

all() ->
    [{group, contact_private},
     {group, group_private}].

groups() ->
    [{contact_private, [set_contact, get_contact]},
     {group_private, [set_group, get_group]}
    ].

suite() ->
    [{require, ejabberd_node} | escalus:suite()].

%%--------------------------------------------------------------------
%% Init & teardown
%%--------------------------------------------------------------------

init_per_suite(Config) ->
    escalus:init_per_suite(Config),
    create_user(Config, phone),
    create_user(Config, email),
    Config.

end_per_suite(Config) ->
    delete_user(Config, phone),
    delete_user(Config, email),
    escalus:end_per_suite(Config).

init_per_group(group_private, Config) ->
    GroupId = create_group(Config, phone, email),
    [{groupid, GroupId} | Config];
init_per_group(_GroupName, Config) ->
    add_roster(Config, phone, email),
    Config.

end_per_group(group_private, Config) ->
    GroupId = proplists:get_value(groupid, Config),
    remove_group(Config, phone, GroupId);
end_per_group(_GroupName, Config) ->
    remove_roster(Config, phone, email).

init_per_testcase(_CaseName, Config) ->
    Config.

end_per_testcase(_CaseName, _Config) ->
    ok.


%%--------------------------------------------------------------------
%% private mode tests
%%--------------------------------------------------------------------

get_contact(Config) ->
    story(Config, phone, escalus_stanza:roster_get()).

set_contact(Config) ->
    Contact = get_jid(Config, email),
    story(Config, phone, set_contact_stanza(Contact)).

get_group(Config) ->
    story(Config, phone, get_groups_stanza()).

set_group(Config) ->
    GroupId = proplists:get_value(groupid, Config),
    story(Config, phone, set_group_stanza(GroupId)).

%%--------------------------------------------------------------------
%% init/end test helper
%%--------------------------------------------------------------------

create_group(Config, Owner, Member) ->
    Jid = get_jid(Config, Member),
    story(Config, Owner, create_group_stanza(Jid), fun(X) ->
                                                           get_groupid(X)
                                                   end).

remove_group(Config, Owner, GroupId) ->
    story(Config, Owner, remove_group_stanza(GroupId)).

add_roster(Config, User, Contact) ->
    Jid = get_jid(Config, Contact),
    roster_story(Config, User, add_roster_stanza(Jid)).

remove_roster(Config, User, Contact) ->
    Jid = get_jid(Config, Contact),
    roster_story(Config, User, remove_roster_stanza(Jid)).

%%--------------------------------------------------------------------
%% Helpers
%%--------------------------------------------------------------------

wait_for_result(Conn) ->
    receive
        {stanza, Conn, Stanza} ->
            case response_type(Stanza) of
                result ->
                    {ok, result, Stanza};
                conflict ->
                    {ok, conflict, Stanza};
                modify ->
                    {ok, modify, Stanza};
                error ->
                    {error, Stanza};
                _ ->
                    {error, bad_response, Stanza}
            end
    after 3000 ->
            {error, timeout, exml:escape_cdata(<<"timeout">>)}
    end.

response_type(#xmlel{name = <<"iq">>} = IQ) ->
    case exml_query:attr(IQ, <<"type">>) of
        <<"result">> ->
            result;
        <<"error">> ->
            error;
        _ ->
            other
    end;
response_type(_) ->
    other.

get_aft_user_by_name(Name) ->
    AftUsers = escalus_ct:get_config(aft_users),
    proplists:lookup(Name, AftUsers).

delete_user(Config, Name) when is_atom(Name) ->
    {_Name, UserSpec} = get_aft_user_by_name(Name),
    delete_user(Config, UserSpec);
delete_user(Config, UserSpec) ->
    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps),
    escalus_connection:send(Conn, remove_user_stanza()),
    wait_for_result(Conn),
    escalus_connection:stop(Conn).

get_jid(Config, Name) ->
    story(Config, Name, escalus_stanza:roster_get(), fun(X) ->
                                                             get_jid_from_stanza(X)
                                                     end).


create_user(Config, Name) ->
    {_Name, UserSpec} = get_aft_user_by_name(Name),

    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps,
                                                          [start_stream,
                                                           stream_features,
                                                           maybe_use_ssl]),
    escalus_connection:send(Conn, create_user_stanza(UserSpec)),
    Result = wait_for_result(Conn),
    escalus_connection:stop(Conn),
    Result.

roster_story(Config, Name, Stanza) ->
    {_, UserSpec} = get_aft_user_by_name(Name),
    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps),
    escalus_connection:send(Conn, Stanza),
    escalus_connection:stop(Conn).

story(Config, Name, Stanza) ->
    story(Config, Name, Stanza, fun(X) -> ok end).
story(Config, Name, Stanza, F) ->
    {_, UserSpec} = get_aft_user_by_name(Name),
    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps),
    escalus_connection:send(Conn, Stanza),
    {ok, result, Result} = wait_for_result(Conn),
    Return = F(Result),
    escalus_connection:stop(Conn),
    Return.

get_jid_from_stanza(#xmlel{name = <<"iq">>} = IQ) ->
    case exml_query:attr(IQ, <<"type">>) of
        <<"result">> ->
            exml_query:attr(IQ, <<"from">>);
        <<"error">> ->
            error
    end.

get_groupid(#xmlel{name = <<"iq">>} = IQ) ->
    case exml_query:attr(IQ, <<"type">>) of
        <<"result">> ->
            exml_query:path(IQ, [{element, <<"query">>},
                                 {attr, <<"groupid">>}]);
        <<"error">> ->
            error
    end.

%%--------------------------------------------------------------------
%% xml stanza
%%--------------------------------------------------------------------

create_user_stanza(UserSpec) ->
    Elements = [#xmlel{name = atom_to_binary(Key, latin1), children = [exml:escape_cdata(proplists:get_value(Key, UserSpec))]}
                || Key <- [phone, email, nick, password], proplists:is_defined(Key, UserSpec)],
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:register">>}],
                              children = Elements}]).

remove_user_stanza() ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:register">>}],
                              children = [#xmlel{name = <<"remove">>}]}]).

get_groups_stanza() ->
    escalus_stanza:iq(<<"get">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:groupchat">>}, {<<"query_type">>, <<"get_groups">>}],
                              children = []}]).

create_group_stanza(Jid) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:groupchat">>}, {<<"query_type">>, <<"group_member">>}],
                              children = [{xmlcdata, [<<"[\"", Jid/binary, "\"]">>]}]}]).

remove_group_stanza(GroupId) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:groupchat">>}, {<<"query_type">>, <<"dismiss_group">>},
                                                           {<<"groupid">>, GroupId}],
                              children = []}]).

set_contact_stanza(Contact) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:privatemode">>}, {<<"query_type">>, <<"contact">>},
                                                           {<<"subject">>, Contact}, {<<"private">>, <<"1">>}],
                              children = []}]).

set_group_stanza(GroupId) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:privatemode">>}, {<<"query_type">>, <<"group">>},
                                                           {<<"subject">>, GroupId}, {<<"private">>, <<"1">>}],
                              children = []}]).

get_roster_stanza() ->
    escalus_stanza:iq(<<"get">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"jabber:iq:roster">>}],
                              children = []}]).

add_roster_stanza(Jid) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"jabber:iq:roster">>}],
                              children = [#xmlel{name = <<"item">>,
                                                 attrs = [{<<"subscription">>, <<"none">>}, {<<"jid">>, Jid}],
                                                 children = []
                                                }]}]).

remove_roster_stanza(Jid) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"jabber:iq:roster">>}],
                              children = [#xmlel{name = <<"item">>,
                                                 attrs = [{<<"subscription">>, <<"remove">>}, {<<"jid">>, Jid}],
                                                 children = []
                                                }]}]).
