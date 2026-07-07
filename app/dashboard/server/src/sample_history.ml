open! Core
open Jsip_exchange_stats

type t =
  { snapshots : Exchange_stats.Snapshot.t Queue.t
  ; capacity : int
  }

let create_exn ~capacity =
  if capacity <= 0
  then
    raise_s
      [%message "Sample_history capacity must be positive" (capacity : int)];
  { snapshots = Queue.create (); capacity }
;;

let add t snapshot =
  Queue.enqueue t.snapshots snapshot;
  if Queue.length t.snapshots > t.capacity
  then ignore (Queue.dequeue_exn t.snapshots : Exchange_stats.Snapshot.t)
;;

let to_list t = Queue.to_list t.snapshots
