%%%-------------------------------------------------------------------
%%% @author neerajsharma
%%% @copyright (C) 2017, Neeraj Sharma <neeraj.sharma@alumni.iitg.ernet.in>
%%% @doc
%%%
%%% The inspiration for implementation of these utility functions is
%%% as follows:
%%%
%%%
%%% * https://git-scm.com/docs/git-status#_short_format
%%% * https://github.com/theia-ide/dugite-extra/blob/master/src/command/
%%%
%%% @end
%%% 
%%% %CopyrightBegin%
%%%
%%% Copyright Neeraj Sharma <neeraj.sharma@alumni.iitg.ernet.in> 2017.
%%% All Rights Reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
%%% %CopyrightEnd%
%%%-------------------------------------------------------------------
-module(beamparticle_git_util).

-export([parse_git_status/1]).
-export([git_status_command/0,
         git_show_command/3,
         git_log_command/1,
         git_branch_command/2,
         git_branch_command/1]).


%% @doc Git command used for retrieving the repo status
%%
%% Git command which generated the content is as follows:
%% git status --untracked-files=all --branch --porcelain -z
git_status_command() ->
    [<<"git">>, <<"status">>, <<"--untracked-files=all">>, <<"--branch">>, <<"--porcelain">>, <<"-z">>].

%% @doc Parse git status output into meaningful information
%%
%%
%% @see git_status_command/0
%%
%%
%% ```
%% A = <<"## master\0M  nlpfn_top_page.erl.fun\0 M test.erl\0A  test3.erl.fun\0M  test_get.erl.fun\0A  test_java2.java.fun\0A  test_python_simple_http.py.fun\0?? res\0?? test.py\0?? test_conditions.erl.fun\0">>,
%% parse_git_status(A)
%% '''
%%
parse_git_status(GitStatusContent) ->
    Lines = string:split(GitStatusContent, <<"\0">>, all),
    [BranchLine | Rest] = Lines,
    <<"## ", BranchName/binary>> = BranchLine,
    ChangedFiles = lists:foldl(fun(<<>>, AccIn) ->
                                       AccIn;
                                  (E, AccIn) ->
                                       [Status, Filename] = binary:split(E, <<" ">>, [global, trim_all]),
                                       FileStatus = maps:get(Filename, AccIn, []),
                                       AccIn#{Filename => [Status | FileStatus]}
                               end, #{}, Rest),
    #{<<"branch">> => BranchName,
      <<"changes">> => ChangedFiles}.


%% @doc Get git file contents at a given reference, commit or tree
%%
%% git show COMMITSHA1:PATH
git_show_command(hash, Hash, RelativeFilePath) ->
    [<<"git">>, <<"show">>, <<Hash/binary, ":", RelativeFilePath/binary>>].

%% @doc Get git log hash for a given file.
%%
%% For short hash:
%%   git log --follow --pretty="%h"
%% For long hash:
%%   git log --follow --pretty="%H"
%%
git_log_command(short) ->
    [<<"git">>, <<"log">>, <<"--follow">>, <<"--pretty=\"%h\"">>];
git_log_command(full) ->
    [<<"git">>, <<"log">>, <<"--follow">>, <<"--pretty=\"%H\"">>].


git_branch_command(list, current) ->
    [<<"git">>, <<"rev-parse">>, <<"--abbrev-ref">>, <<"HEAD">>].

git_branch_command(list_branches) ->
    [<<"git">>, <<"for-each-ref">>, <<"--format=\"%(refname)%00%(refname:short)%00%(upstream:short)%00%(objectname)%00%(author)%00%(parent)%00%(subject)%00%(body)%00\"">>, <<"HEAD">>].