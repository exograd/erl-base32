%% Copyright (c) 2021 Bryan Frimin <bryan@frimin.fr>.
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
%% SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
%% IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(base32).

-export([encode/1, decode/1]).

-spec encode(binary()) -> binary().
encode(Bin) when is_binary(Bin) ->
  encode(Bin, <<>>).

-spec encode(binary(), binary()) -> binary().
encode(<<>>, Acc) ->
  Acc;
encode(<<A0:5, B0:5, C0:5, D0:5, E0:5, F0:5, G0:5, H0:5, Rest/binary>>, Acc) ->
  A = enc_b32_digit(A0),
  B = enc_b32_digit(B0),
  C = enc_b32_digit(C0),
  D = enc_b32_digit(D0),
  E = enc_b32_digit(E0),
  F = enc_b32_digit(F0),
  G = enc_b32_digit(G0),
  H = enc_b32_digit(H0),
  encode(Rest, <<Acc/binary, A, B, C, D, E, F, G, H>>);
encode(<<A0:5, B0:5, C0:5, D0:5, E0:5, F0:5, G0:2>>, Acc) ->
  A = enc_b32_digit(A0),
  B = enc_b32_digit(B0),
  C = enc_b32_digit(C0),
  D = enc_b32_digit(D0),
  E = enc_b32_digit(E0),
  F = enc_b32_digit(F0),
  G = enc_b32_digit(G0 bsl 3),
  encode(<<>>, <<Acc/binary, A, B, C, D, E, F, G, $=>>);
encode(<<A0:5, B0:5, C0:5, D0:5, E0:4>>, Acc) ->
  A = enc_b32_digit(A0),
  B = enc_b32_digit(B0),
  C = enc_b32_digit(C0),
  D = enc_b32_digit(D0),
  E = enc_b32_digit(E0 bsl 1),
  encode(<<>>, <<Acc/binary, A, B, C, D, E, $=, $=, $=>>);
encode(<<A0:5, B0:5, C0:5, D0:1>>, Acc) ->
  A = enc_b32_digit(A0),
  B = enc_b32_digit(B0),
  C = enc_b32_digit(C0),
  D = enc_b32_digit(D0 bsl 4),
  encode(<<>>, <<Acc/binary, A, B, C, D, $=, $=, $=, $=>>);
encode(<<A0:5, B0:3>>, Acc) ->
  A = enc_b32_digit(A0),
  B = enc_b32_digit(B0 bsl 2),
  encode(<<>>, <<Acc/binary, A, B, $=, $=, $=, $=, $=, $=>>).


-spec enc_b32_digit(0..31) -> $A..$Z | $2..$7.
enc_b32_digit(Digit) when Digit =< 25 ->
  Digit + 65;
enc_b32_digit(Digit) when Digit =< 31 ->
  Digit + 24.

-spec decode(binary()) -> {ok, binary()} | {error, term()}.
decode(Bin) ->
  try
    {ok, decode(Bin, <<>>)}
  catch
    throw:{error, Reason} ->
      {error, Reason}
  end.

-spec decode(binary(), binary()) -> binary().
decode(<<>>, Acc) ->
  Acc;
decode(<<A0:8, B0:8, $=, $=, $=, $=, $=, $=>>, Acc) ->
  A = dec_b32_char(A0),
  B = dec_b32_char(B0) bsr 2,
  decode(<<>>, <<Acc/binary, A:5, B:3>>);
decode(<<A0:8, B0:8, C0:8, D0:8, $=, $=, $=, $=>>, Acc) ->
  A = dec_b32_char(A0),
  B = dec_b32_char(B0),
  C = dec_b32_char(C0),
  D = dec_b32_char(D0) bsr 4,
  decode(<<>>, <<Acc/binary, A:5, B:5, C:5, D:1>>);
decode(<<A0:8, B0:8, C0:8, D0:8, E0:8, $=, $=, $=>>, Acc) ->
  A = dec_b32_char(A0),
  B = dec_b32_char(B0),
  C = dec_b32_char(C0),
  D = dec_b32_char(D0),
  E = dec_b32_char(E0) bsr 1,
  decode(<<>>, <<Acc/binary, A:5, B:5, C:5, D:5, E:4>>);
decode(<<A0:8, B0:8, C0:8, D0:8, E0:8, F0:8, G0:8, $=>>, Acc) ->
  A = dec_b32_char(A0),
  B = dec_b32_char(B0),
  C = dec_b32_char(C0),
  D = dec_b32_char(D0),
  E = dec_b32_char(E0),
  F = dec_b32_char(F0),
  G = dec_b32_char(G0) bsr 3,
  decode(<<>>, <<Acc/binary, A:5, B:5, C:5, D:5, E:5, F:5, G:2>>);
decode(<<A0:8, B0:8, C0:8, D0:8, E0:8, F0:8, G0:8, H0:8, Rest/binary>>, Acc) ->
  A = dec_b32_char(A0),
  B = dec_b32_char(B0),
  C = dec_b32_char(C0),
  D = dec_b32_char(D0),
  E = dec_b32_char(E0),
  F = dec_b32_char(F0),
  G = dec_b32_char(G0),
  H = dec_b32_char(H0),
  decode(Rest, <<Acc/binary, A:5, B:5, C:5, D:5, E:5, F:5, G:5, H:5>>);
decode(Bin, _) ->
  throw({error, invalid_base32}).

-spec dec_b32_char($A..$Z | $2..$7) -> 0..31.
dec_b32_char(Char) when Char >= $A, Char =< $Z ->
  Char - 65;
dec_b32_char(Char) when Char >= $2, Char =< $7 ->
  Char - 24;
dec_b32_char(Char) ->
  throw({error, {invalid_base32, <<Char>>}}).
