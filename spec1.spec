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
{suites, "tests", bosh_SUITE}.
{suites, "tests", carboncopy_SUITE}.
{suites, "tests", ejabberdctl_SUITE}.
{suites, "tests", last_SUITE}.
{suites, "tests", login_SUITE}.
{config, ["test.config"]}.
{logdir, "ct_report"}.
{ct_hooks, [ct_tty_hook]}.
