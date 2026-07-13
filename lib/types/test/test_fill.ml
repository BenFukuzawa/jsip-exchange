open! Core
open Jsip_types

let%expect_test "notional_cents: price * size" =
  let fill =
    ({ fill_id = 1
     ; symbol = Symbol_id.of_int 0
     ; price = Price.of_int_cents 15025
     ; size = Size.of_int 100
     ; aggressor_order_id = Order_id.of_string "1"
     ; aggressor_participant = Participant.of_string "Alice"
     ; aggressor_side = Buy
     ; resting_order_id = Order_id.of_string "2"
     ; resting_participant = Participant.of_string "Bob"
     ; aggressor_client_order_id = Client_order_id.of_int 1001
     ; resting_client_order_id = Client_order_id.of_int 1002
     }
     : Fill.t)
  in
  [%test_result: int] (Fill.notional_cents fill) ~expect:1502500
;;

let%expect_test "participant view" =
  let fill =
    ({ fill_id = 1
     ; symbol = Symbol_id.of_int 0
     ; price = Price.of_int_cents 15025
     ; size = Size.of_int 100
     ; aggressor_order_id = Order_id.of_string "1"
     ; aggressor_participant = Participant.of_string "Alice"
     ; aggressor_side = Buy
     ; resting_order_id = Order_id.of_string "2"
     ; resting_participant = Participant.of_string "Bob"
     ; aggressor_client_order_id = Client_order_id.of_int 1001
     ; resting_client_order_id = Client_order_id.of_int 1002
     }
     : Fill.t)
  in
  (* Phase 1: [lib/types] is int-only, so the participant view renders the
     symbol as its raw id (0). Phase 2's directory is what restores "AAPL". *)
  let res = Some "You bought 100 0 at $150.25" in
  [%test_result: string option]
    (Fill.to_participant_view fill (Participant.of_string "Alice"))
    ~expect:res
;;
