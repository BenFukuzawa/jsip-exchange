open! Core

module Build_list = struct
  (* [acc @ [ x ]] copies the whole accumulator each step -> O(n^2)
     allocation. *)
  let silly xs =
    let rec aux acc = function
      | [] -> acc
      | hd :: tl -> aux (acc @ [ hd ]) tl
    in
    aux [] xs
  ;;

  (* Prepend (O(1) per step) then reverse once -> O(n) allocation. Same
     result. *)
  let non_silly xs =
    let rec aux acc = function
      | [] -> List.rev acc
      | hd :: tl -> aux (hd :: acc) tl
    in
    aux [] xs
  ;;
end

module First_match = struct
  (* Allocate a fresh list of *every* match, then throw all but the head
     away. *)
  let silly xs ~f = List.filter xs ~f |> List.hd

  (* Stop at the first match; allocate nothing but the returned [Some]. *)
  let non_silly xs ~f = List.find xs ~f
end
