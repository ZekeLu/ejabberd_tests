%% Spec examples:
%%
%%   {suites, "tests", amp_SUITE}.
%%   {groups, "tests", amp_SUITE, [discovery]}.
%%   {groups, "tests", amp_SUITE, [discovery], {cases, [stream_feature_test]}}.
%%   {cases, "tests", amp_SUITE, [stream_feature_test]}.
%%
%% For more info see:
%% http://www.erlang.org/doc/apps/common_test/run_test_chapter.html#test_specifications

%% mam_SUITE, configurations: odbc_mult_cache, odbc_mnesia_cache, odbc_mnesia_muc_cache
{groups, "tests", mam_SUITE, [
    odbc_mult_cache_mam,
    odbc_mult_cache_mam_purge,
    odbc_mult_cache_muc,
    odbc_mult_cache_muc_with_pm,
    odbc_mult_cache_rsm,
    odbc_mult_cache_with_rsm,
    odbc_mult_cache_muc_rsm,
    odbc_mult_cache_bootstrapped,
    odbc_mult_cache_archived,
    odbc_mult_cache_policy_violation,
    odbc_mult_cache_offline_message,
    odbc_mnesia_cache_mam,
    odbc_mnesia_cache_mam_purge,
    odbc_mnesia_cache_muc,
    odbc_mnesia_cache_muc_with_pm,
    odbc_mnesia_cache_rsm,
    odbc_mnesia_cache_with_rsm,
    odbc_mnesia_cache_muc_rsm,
    odbc_mnesia_cache_bootstrapped,
    odbc_mnesia_cache_archived,
    odbc_mnesia_cache_policy_violation,
    odbc_mnesia_cache_offline_message,
    odbc_mnesia_muc_cache_mam,
    odbc_mnesia_muc_cache_mam_purge,
    odbc_mnesia_muc_cache_with_rsm,
    odbc_mnesia_muc_cache_muc_rsm,
    odbc_mnesia_muc_cache_bootstrapped,
    odbc_mnesia_muc_cache_archived,
    odbc_mnesia_muc_cache_policy_violation,
    odbc_mnesia_muc_cache_offline_message
]}.
{config, ["test.config"]}.
{logdir, "ct_report"}.
{ct_hooks, [ct_tty_hook]}.
