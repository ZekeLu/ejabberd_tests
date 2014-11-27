%% Spec examples:
%%
%%   {suites, "tests", amp_SUITE}.
%%   {groups, "tests", amp_SUITE, [discovery]}.
%%   {groups, "tests", amp_SUITE, [discovery], {cases, [stream_feature_test]}}.
%%   {cases, "tests", amp_SUITE, [stream_feature_test]}.
%%
%% For more info see:
%% http://www.erlang.org/doc/apps/common_test/run_test_chapter.html#test_specifications

{suites, "tests", adhoc_SUITE}.
{suites, "tests", aft_register_SUITE}.
{suites, "tests", amp_SUITE}.
{suites, "tests", carboncopy_SUITE}.
{suites, "tests", ejabberdctl_SUITE}.
{suites, "tests", last_SUITE}.
{suites, "tests", login_SUITE}.
%% the BOSH client will send this request to the server when the connection is closing even after the user is unregistered.
%%   <body type='terminate' sid='sid1' xmlns='http://jabber.org/protocol/httpbind' rid='rid1'>
%%     <presence type='unavailable'/>
%%   </body>
%% when the server receive this request, it will upsert the "last" table.
%% in some cases, the upsertion will happen after the deletion so the record for the unregistered user will be left in the table
%% which will affect other tests. So we move the bost_SUITE to the last
{suites, "tests", bosh_SUITE}.
{config, ["test.config"]}.
{logdir, "ct_report"}.
{ct_hooks, [ct_tty_hook]}.
