-module(ejabberd_node_utils).

-export([init/1, call_fun/3, call_ctl/2,
         backup_config_file/1, restore_config_file/1, modify_config_file/2]).

-include_lib("common_test/include/ct.hrl").

-define(CWD(Config), ?config(ejabberd_node_cwd, Config)).
-define(CURRENT_CFG_PATH(Config),
        filename:join([?CWD(Config), "etc", "ejabberd.cfg"])).
-define(BACKUP_CFG_PATH(Config),
        filename:join([?CWD(Config), "etc","ejabberd.cfg.bak"])).
-define(CFG_TEMPLATE_PATH(Config),
        filename:join([?CWD(Config), "..", "..", "rel", "files",
                       "ejabberd.cfg"])).
-define(CFG_VARS_PATH(Config),
        filename:join([?CWD(Config), "..", "..", "rel",
                       "vars.config"])).
-define(CTL_PATH(Config),
        filename:join([?CWD(Config), "bin", "mongooseimctl"])).

%%--------------------------------------------------------------------
%% API
%%--------------------------------------------------------------------

init(Config) ->
    set_ejabberd_node_cwd(Config).

set_ejabberd_node_cwd(Config) ->
    {ok, Cwd} = call_fun(file, get_cwd, []),
    [{ejabberd_node_cwd, Cwd} | Config].

backup_config_file(Config) ->
    {ok, _} = call_fun(file, copy, [?CURRENT_CFG_PATH(Config),
                                         ?BACKUP_CFG_PATH(Config)]).

restore_config_file(Config) ->
    ok = call_fun(file, rename, [?BACKUP_CFG_PATH(Config),
                                      ?CURRENT_CFG_PATH(Config)]).

call_fun(M, F, A) ->
    Node = ct:get_config(ejabberd_node),
    rpc:call(Node, M, F, A).

call_ctl(Config, Cmd) ->
    OsCmd = io_lib:format("~p ~p", [?CTL_PATH(Config), atom_to_list(Cmd)]),
    call_fun(os, cmd, [OsCmd]).

modify_config_file(CfgVarsToChange, Config) ->
    CurrentCfgPath = ?CURRENT_CFG_PATH(Config),
    {ok, CfgTemplate} = ejabberd_node_utils:call_fun(
                          file, read_file, [?CFG_TEMPLATE_PATH(Config)]),
    {ok, CfgVars} = ejabberd_node_utils:call_fun(file, consult,
                                                 [?CFG_VARS_PATH(Config)]),
    UpdatedCfgVars = update_config_variables(CfgVarsToChange, CfgVars),
    CfgTemplateList = binary_to_list(CfgTemplate),
    UpdatedCfgFile = mustache:render(CfgTemplateList,
                                     dict:from_list(UpdatedCfgVars)),
    ok = ejabberd_node_utils:call_fun(file, write_file, [CurrentCfgPath,
                                                         UpdatedCfgFile]).

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------

update_config_variables(CfgVarsToChange, CfgVars) ->
    lists:foldl(fun({Var, Val}, Acc) ->
                        lists:keystore(Var, 1, Acc,{Var, Val})
                end, CfgVars, CfgVarsToChange).




