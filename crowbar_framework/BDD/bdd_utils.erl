% Copyright 2012, Dell 
% 
% Licensed under the Apache License, Version 2.0 (the "License"); 
% you may not use this file except in compliance with the License. 
% You may obtain a copy of the License at 
% 
%  http://www.apache.org/licenses/LICENSE-2.0 
% 
% Unless required by applicable law or agreed to in writing, software 
% distributed under the License is distributed on an "AS IS" BASIS, 
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
% See the License for the specific language governing permissions and 
% limitations under the License. 
% 
% Author: RobHirschfeld 
% 
-module(bdd_utils).
-export([assert/1, assert/2, assert_atoms/1, config/2, tokenize/1, clean_line/1, uri/2]).
-export([http_get/2, http_get/3, html_peek/2, html_search/2, html_search/3]).
-export([html_find_button/2, html_find_link/2, html_find_block/4]).
-export([debug/3, debug/2, debug/1, trace/6]).
-export([http_post_params/1, http_post/5]).

assert(Bools) ->
	assert(Bools, true).
assert(Bools, Test) ->
	F = fun(X) -> case X of Test -> true; _ -> false end end,
	lists:all(F, Bools).
assert_atoms(Atoms) ->
  assert([B || {B, _} <- Atoms] ).
	
debug(Format) -> debug(Format, []).
debug(puts, Format) -> debug(true, Format++"~n", []);
debug(true, Format) -> debug(true, Format, []);
debug(false, Format) -> debug(false, Format, []);
debug(Format, Data) -> debug(false, Format, Data).
debug(Show, Format, Data) ->
  case Show of
    true -> io:format("DEBUG: " ++ Format, Data);
    _ -> noop
  end.

% Return the file name for the test.  
trace_setup(Config, Name, nil) ->
  trace_setup(Config, Name, 0);

trace_setup(Config, Name, N) ->
  SafeName = clean_line(Name),
  string:join(["trace_", config(Config,feature), "-", string:join(string:tokens(SafeName, " "), "_"), "-", integer_to_list(N), ".txt"], "").
  
trace(Config, Name, N, Steps, Given, When) ->
  File = trace_setup(Config, Name, N),
  {ok, S} = file:open(File, write),
  lists:foreach(fun(X) -> io:format(S, "~n==== Step ====~n~p", [X]) end, Steps),
  lists:foreach(fun(X) -> io:format(S, "~n==== Given ====~n~p", [X]) end, Given),
  [io:format(S, "~n==== When ====~n~p",[X]) || X <- (When), X =/= []],
  io:format(S, "~n==== End of Test Dump (~p) ====", [N]),
  file:close(S).
 
html_search(Match, Results, Test) ->
  debug(true, "REMAP bdd_utils html_search!"),
  html:search(Match, Results, Test).

html_search(Match, Results) ->
	html_search(Match, Results, true).


html_peek(Match, Input) ->
  debug(true, "REMAP bdd_utils html_peek!"),
  html:peek(Match, Input).	
	
html_find_button(Match, Input) ->
  debug(true, "REMAP bdd_utils html_find_button!"),
  %<form.. <input class="button" name="submit" type="submit" value="Save"></form>
  %debug(puts,Match),
	Form = html_find_block("<form ", "</form>", Input, "value='"++Match++"'"),
	%debug(puts,Form),
	Button = html_find_block("<input ", ">", Form,  "value='"++Match++"'"),
	%debug(puts,Button),
	{ok, RegEx} = re:compile("type='submit'"),
	case re:run(Button, RegEx) of
	  {match, _} -> Button;
	  _ -> io:format("ERROR: Could not find button with value  '~p'.  HTML could have other components encoded in a tag~n", [Match]), throw("could not html_find_button")
	end.
	
% return the HREF part of an anchor tag given the content of the link
html_find_link(Match, Input) ->
  debug(true, "REMAP bdd_utils html_find_link!"),
	RegEx = "(\\<(a|A)\\b(/?[^\\>]+)\\>"++Match++"\\<\\/(a|A)\\>)",
	RE = case re:compile(RegEx, [multiline, dotall, {newline , anycrlf}]) of
	  {ok, R} -> R;
	  Error -> io:format("ERROR: Could not parse regex: '~p'.", [Error])
	end,
	AnchorTag = case re:run(Input, RE) of
	  {match, [{AStart, ALength} | _]} -> string:substr(Input, AStart+1,AStart+ALength);
	  {_, _} -> io:format("ERROR: Could not find Anchor tags enclosing '~p'.  HTML could have other components encoded in a tag~n", [Match]), throw("could not html_find_link")
	end,
	{ok, HrefREX} = re:compile("\\bhref=(['\"])([^\\s]+?)(\\1)", [multiline, dotall, {newline , anycrlf}]),
	Href = case re:run(AnchorTag, HrefREX) of
	  {match, [_1, _2, {HStart, HLength} | _]} -> string:substr(AnchorTag, HStart+1,HLength);
	  {_, _} -> io:format("ERROR: Could not find href= information in substring '~p'~n", [AnchorTag]), throw("could not html_find_link")
	end,
	bdd_utils:debug("html_find_link anchor ~p~n", [AnchorTag]),
	%bdd_utils:debug(, "html_find_link href regex~p~n", [re:run(AnchorTag, HrefREX)]),
	bdd_utils:debug("html_find_link found path ~p~n", [Href]),
	Href.

% we allow for a of open tags (nesting) but only the inner close is needed
html_find_block(OpenTag, CloseTag, Input, Match) ->
  debug(true, "REMAP bdd_utils html_find_block!"),
  {ok, RE} = re:compile([Match]),
  CandidatesNotTested = re:split(Input, OpenTag, [{return, list}]),
  Candidates = [ html_find_block_helper(C, RE) || C <- CandidatesNotTested ],
  Block = case [ C || C <- Candidates, C =/= false ] of
    [B] -> B;
    [B, _] -> B;
    _ -> []
  end,
  [Inside | _ ] = re:split(Block, CloseTag, [{parts, 2}, {return, list}]),
  [Inside].

html_find_block_helper(Test, RE) ->
	case re:run(Test, RE) of
		{match, _} -> Test;
		_ -> false
	end.

uri(Config, Path) ->
	{url, Base} = lists:keyfind(url,1,Config),
  case {string:right(Base,1),string:left(Path,1)} of
    {"/", "/"}-> Base ++ string:substr(Path,2);
    {_, "/"}  -> Base ++ Path;
    {"/", _}  -> Base ++ Path;
    {_, _}    -> Base ++ "/" ++ Path
  end.
  
% get a page from a server
http_get(Config, Page) ->
	http_get(Config, Page, ok).
http_get(Config, Page, not_found) ->
	http_get(uri(Config,Page), 404, "Not Found");
http_get(Config, Page, ok) ->
	http_get(Config, uri(Config,Page), 200, "OK(.*)").
http_get(Config, URL, ReturnCode, StateRegEx) ->
  debug(true, "REMAP bdd_utils html_get!"),
	{ok, {{"HTTP/1.1",ReturnCode,State}, _Head, Body}} = digest_auth:request(Config, URL),
	{ok, StateMP} = re:compile(StateRegEx),
	%bdd_utils:debug(true, "hppt_get has: URL ~p = ~s~n", [URL, Body]),
	case re:run(State, StateMP) of
		{match, _} -> Body;
		_ -> "ERROR, return of " ++ URL ++ " result was not 200 OK"
	end.

http_post_params(ParamsIn) -> http_post_params(ParamsIn, []).
http_post_params([], Params) -> Params;
http_post_params([{K, V} | P], ParamsOrig) -> 
  debug(true, "REMAP bdd_utils html_post_params!"),
  ParamsAdd = case ParamsOrig of
    [] -> "?"++K++"="++V;
    _ -> "&"++K++"="++V
  end,
  http_post_params(P, ParamsOrig++ParamsAdd).

http_post(Config, URL, Parameters, ReturnCode, StateRegEx) ->
  debug(true, "REMAP bdd_utils html_post!"),
  Post = URL ++ http_post_params(Parameters),
  {ok, {{"HTTP/1.1",ReturnCode, State}, _Head, Body}} = digest_auth:request(Config, post, {Post, "application/json", "application/json", "body"}, [{timeout, 10000}], []),  
 	{ok, StateMP} = re:compile(StateRegEx),
	case re:run(State, StateMP) of
		{match, _} -> Body;
		_ -> "ERROR, return of " ++ URL ++ " result was not 200 OK"
	end. 

config(Config, Key) ->
	case lists:keyfind(Key,1,Config) of
	  {Key, Value} -> Value;
	  false -> throw("Could not find requested key in config file");
	  _ -> throw("Unexpected return from keyfind")
	end.

clean_line(Raw) ->
	CleanLine0 = string:strip(Raw),
	CleanLine1 = string:strip(CleanLine0, left, $\t),
	CleanLine11 = string:strip(CleanLine1, right, $\r),
	CleanLine2 = string:strip(CleanLine11),
	string:strip(CleanLine2, right, $.).

tokenize(Step) ->
	Tokens = string:tokens(Step,"\""),
	[string:strip(X) || X<- Tokens].
