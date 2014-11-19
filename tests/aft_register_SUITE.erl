%%%===================================================================
%%% @doc test registering with telephone and email
%%%===================================================================

-module(aft_register_SUITE).
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
    [{group, registration},
     {group, change_password}].

groups() ->
    [{registration, [register_with_phone,
                     register_with_email,
                     register_with_phone_and_email,
                     register_with_weak_password]},
     {change_password, [change_password]}
    ].

suite() ->
    [{require, ejabberd_node} | escalus:suite()].

%%--------------------------------------------------------------------
%% Init & teardown
%%--------------------------------------------------------------------

init_per_suite(Config) ->
    escalus:init_per_suite(Config).

end_per_suite(Config) ->
    escalus:end_per_suite(Config).

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, _Config) ->
    ok.

init_per_testcase(change_password, Config) ->
    do_register(Config, phone),
    [{new_password, <<"deih38js">>} | Config];
init_per_testcase(_CaseName, Config) ->
    Config.

end_per_testcase(register_with_phone, Config) ->
    delete_user(Config, phone);
end_per_testcase(register_with_email, Config) ->
    delete_user(Config, email);
end_per_testcase(register_with_phone_and_email, Config) ->
    delete_user(Config, phone_and_email);
end_per_testcase(change_password, Config) ->
    {_Name, UserSpec} = get_aft_user_by_name(phone),
    NewUserSpec = proplists:delete(password, UserSpec),
    NewPassword = proplists:get_value(new_password, Config),
    delete_user(Config, [{password, NewPassword} | NewUserSpec]);
end_per_testcase(_CaseName, _Config) ->
    ok.

%%--------------------------------------------------------------------
%% Registration tests
%%--------------------------------------------------------------------

register_with_phone(Config) ->
    {value, Registarations} = get_counter_value(modRegisterCount),

    do_register(Config, phone),

    assert_counter(Registarations + 1, modRegisterCount).

register_with_email(Config) ->
    {value, Registarations} = get_counter_value(modRegisterCount),

    do_register(Config, email),

    assert_counter(Registarations + 1, modRegisterCount).

register_with_phone_and_email(Config) ->
    {value, Registarations} = get_counter_value(modRegisterCount),

    do_register(Config, phone_and_email),

    assert_counter(Registarations + 1, modRegisterCount).

register_with_weak_password(Config) ->
    {value, Registarations} = get_counter_value(modRegisterCount),

    Result = do_register(Config, weak_password),

    {ok, modify, _} = Result,

    assert_counter(Registarations, modRegisterCount).

%%--------------------------------------------------------------------
%% Change password tests
%%--------------------------------------------------------------------

change_password(Config) ->
    {_Name, UserSpec} = get_aft_user_by_name(phone),

    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps),
    OldPassword = proplists:get_value(password, UserSpec),
    NewPassword = proplists:get_value(new_password, Config),
    escalus_connection:send(Conn, change_password_stanza(OldPassword, NewPassword)),
    {ok, result, _} = wait_for_result(Conn),
    escalus_connection:stop(Conn).


%%--------------------------------------------------------------------
%% Helpers
%%--------------------------------------------------------------------
do_register(Config, Name) ->
    {_Name, UserSpec} = get_aft_user_by_name(Name),

    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps,
                                                          [start_stream,
                                                           stream_features,
                                                           maybe_use_ssl]),
    escalus_connection:send(Conn, register_account(UserSpec)),
    Result = wait_for_result(Conn),
    escalus_connection:stop(Conn),
    Result.

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
                    {error, failed_to_register, Stanza};
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
            case exml_query:path(IQ, [{element, <<"error">>},
                                      {attr, <<"code">>}]) of
                <<"409">> ->
                    conflict;
                <<"406">> ->
                    modify;
                _ ->
                    error
            end;
        _ ->
            other
    end;
response_type(_) ->
    other.

register_account(UserSpec) ->
    Elements = [#xmlel{name = atom_to_binary(Key, latin1), children = [exml:escape_cdata(proplists:get_value(Key, UserSpec))]}
                || Key <- [phone, email, nick, password], proplists:is_defined(Key, UserSpec)],
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:register">>}],
                              children = Elements}]).

get_aft_user_by_name(Name) ->
    AftUsers = escalus_ct:get_config(aft_users),
    proplists:lookup(Name, AftUsers).

remove_account() ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:register">>}],
                              children = [#xmlel{name = <<"remove">>}]}]).

change_password_stanza(OldPassword, NewPassword) ->
    escalus_stanza:iq(<<"set">>,
                      [#xmlel{name = <<"query">>, attrs = [{<<"xmlns">>, <<"aft:register">>}],
                              children = [#xmlel{name = <<"old_password">>, children = [exml:escape_cdata(OldPassword)]},
                                          #xmlel{name = <<"password">>, children = [exml:escape_cdata(NewPassword)]}]
                             }
                      ]).

delete_user(Config, Name) when is_atom(Name) ->
    {_Name, UserSpec} = get_aft_user_by_name(Name),
    delete_user(Config, UserSpec);
delete_user(Config, UserSpec) ->
    ClientProps = escalus_users:get_options(Config, UserSpec),
    {ok, Conn, ClientProps, _} = escalus_connection:start(ClientProps),
    escalus_connection:send(Conn, remove_account()),
    wait_for_result(Conn),
    escalus_connection:stop(Conn).
