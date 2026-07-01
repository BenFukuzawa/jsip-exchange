window.BENCHMARK_DATA = {
  "lastUpdate": 1782920097423,
  "repoUrl": "https://github.com/BenFukuzawa/jsip-exchange",
  "entries": {
    "Order book benchmark": [
      {
        "commit": {
          "author": {
            "email": "115841955+BenFukuzawa@users.noreply.github.com",
            "name": "BenFukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "a79bd21f887d560d89ea587e8e5a7a62b5089a85",
          "message": "Merge branch 'jane-street-immersion-program:main' into main",
          "timestamp": "2026-06-17T15:24:57-04:00",
          "tree_id": "b105f708f1d0a3bfac0fc8f703926fc5cb5958f3",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/a79bd21f887d560d89ea587e8e5a7a62b5089a85"
        },
        "date": 1781724534612,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 26.228369479158534,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 26.209091606341957,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 25.2830083165683,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 25.732374213191136,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 129.57671872427778,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 583.8307828225975,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1149.8548285024162,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5656.941873373026,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 249.89999959361504,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1179.0341358363187,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2345.7689778501963,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11642.239060609225,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1714.9182319963027,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1293.655171952765,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 4984.030635912138,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 9972.099807200888,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 48600.38069785453,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 691.9015384693254,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3033.6039834811527,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5932.605578598176,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 26671.01304231322,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 5596.809171966923,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 89153.00776093079,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 330875.8858972507,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 26.271583028883366,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "9c425c173ee64de850664fff8b7ad8ba87ba8d10",
          "message": "Merge branch 'main' of github.com:BenFukuzawa/jsip-exchange",
          "timestamp": "2026-06-17T20:46:31Z",
          "tree_id": "9a25bdb400650effe9fe8a894033d3c2586882b6",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/9c425c173ee64de850664fff8b7ad8ba87ba8d10"
        },
        "date": 1781729432774,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 191.47858779716702,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1021.9558193303875,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2070.021968064221,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 9811.827253832507,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 192.03350356716987,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 961.6119994646128,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1935.5805537089245,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 9511.840614530669,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 248.21084540826467,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1126.376104091738,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2248.0024377707155,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11346.773107762308,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1746.799295608934,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1624.2052967682891,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 6945.96909410393,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 13432.87678529649,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 64421.39048314282,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 106.98059570772453,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 106.1198882307129,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 106.04338956855776,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 108.44061123229264,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 6610.7086537075475,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 113986.4670624644,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 445667.7795398181,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2050.618136926942,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "42f04be6b5e450b0bfab983561487616c0d92aeb",
          "message": "Ex 2 completed. Ex 8 in progress",
          "timestamp": "2026-06-18T20:12:33Z",
          "tree_id": "d31d8b95240df1cbbf970d565443da47079af9f4",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/42f04be6b5e450b0bfab983561487616c0d92aeb"
        },
        "date": 1781814016853,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 323.4347511017206,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1604.4309734766912,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 3227.2227573244422,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 15616.899195776812,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 112.81699126374069,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 493.9864562376152,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 933.0199579790797,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4510.182106199811,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 266.24162818457984,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1168.9800155291687,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2143.0354079825925,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11850.044944497815,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1633.3686873852193,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1790.9072483791308,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7452.024696389462,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 14741.87446976659,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 69295.3910170005,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 731.5289347971565,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3131.5642523277843,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6078.934972939074,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 30107.093805126708,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7307.203722275722,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 130352.21166111667,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 480878.85518472985,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 3170.517722160718,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "baa6e911896624827e596a12ba7f350cf07562be",
          "message": "partial implementation of ex8",
          "timestamp": "2026-06-18T21:27:32Z",
          "tree_id": "b435ccab54a3ed6d8254aa04c51a4b5f23a49cce",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/baa6e911896624827e596a12ba7f350cf07562be"
        },
        "date": 1781818300438,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 339.3622456812955,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1704.6705847162514,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 3395.562184204249,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 15134.62700919692,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 111.96032061668001,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 492.5900671545724,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 949.8290319640726,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4787.178801267832,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 258.48705342154915,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1191.89509914473,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2367.5192853647063,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11764.589152266983,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1441.3056888548344,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1793.4750862772719,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7133.227995861189,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 15086.816370547502,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 72719.04345458484,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 691.7331115582472,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2778.2666262436533,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5466.053494099911,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 26312.864041384575,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7213.008989420206,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 123313.46267631862,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 468778.79144839087,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 3128.55827623265,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "338ad74dc2da60466d29f02b3672eabb2854bd78",
          "message": "ex8 ongoing",
          "timestamp": "2026-06-22T14:22:57Z",
          "tree_id": "d2baadc52c25670d14cf207c82c478dcb6dd3486",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/338ad74dc2da60466d29f02b3672eabb2854bd78"
        },
        "date": 1782138440617,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 322.43283280686603,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1571.3461637031905,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 3146.2720194272215,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 15952.053119018503,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 114.94984586428986,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 546.2378778463325,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1058.2400798466144,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4810.847917929504,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 253.41495698034208,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1127.2698567991029,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2386.696499142554,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 12010.882073075163,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1576.5919274239673,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1722.2838355732638,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7637.959098459212,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 14891.966958448098,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 73450.63285182412,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 722.7069916679336,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3107.768891890011,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6147.15013872198,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 30485.5503630186,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7269.782092563137,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 135804.98104817735,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 512359.52332023345,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 3220.592767364054,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "115841955+BenFukuzawa@users.noreply.github.com",
            "name": "BenFukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "e2f197f82f85a70fc5fce1834f81aac3f9aefad4",
          "message": "Merge branch 'jane-street-immersion-program:main' into main",
          "timestamp": "2026-06-22T10:23:13-04:00",
          "tree_id": "ff5776291a12edba5167fcf9435b53e31a684614",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/e2f197f82f85a70fc5fce1834f81aac3f9aefad4"
        },
        "date": 1782138475506,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 296.2310550133968,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1495.2703157372457,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2986.6982604934738,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 14800.83451827203,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 110.50994459827636,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 522.3752158277639,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 959.4504602409348,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4666.805329169569,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 239.47050781071124,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1097.7551786314134,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2210.5767081051827,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11438.900733841574,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1585.1127097199915,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1589.9433855400432,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 6901.503748305323,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 13499.019664420299,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 65832.2815142353,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 669.9978939899803,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2936.2727779352326,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5725.641574492341,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 27906.315603292103,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 6899.605747106223,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 123506.27965391817,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 467084.4143742728,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2943.15284427997,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "22b25ea7923e0a1890e6b720c75fba0be756b761",
          "message": "Merge branch 'main' of github.com:BenFukuzawa/jsip-exchange",
          "timestamp": "2026-06-22T14:26:03Z",
          "tree_id": "ff5776291a12edba5167fcf9435b53e31a684614",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/22b25ea7923e0a1890e6b720c75fba0be756b761"
        },
        "date": 1782138650934,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 341.6572956140698,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1705.4833958215097,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 3038.7471245085285,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 15161.90216224674,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 112.56317709822919,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 479.06367396308144,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 946.2809815578174,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5128.769677974541,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 271.4642103726467,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1248.6643726329403,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2576.3934350890468,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 12023.227674887064,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1668.391495889461,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1786.7254615202307,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7934.645560286203,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 15646.9531814873,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 70435.4857118826,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 710.1378024158777,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3033.003719654438,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5942.735606478271,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 30437.375821850037,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7551.432118788119,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 131468.7992152292,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 514451.9323289071,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 3296.046550742009,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "d22a80f4cb9757122b3a607039498fae5d039b3d",
          "message": "Part 2 start",
          "timestamp": "2026-06-22T21:06:38Z",
          "tree_id": "af9fa91930dd0b34e7202163c93b50083e13f78d",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/d22a80f4cb9757122b3a607039498fae5d039b3d"
        },
        "date": 1782162625005,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 257.5547447269031,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1182.9853704643922,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2393.139137723068,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 11857.606985319371,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 87.53523487849489,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 381.7939392030035,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 745.5487030152309,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4085.8390905877936,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 209.01070099631693,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 955.290048395717,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1862.59209003142,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9185.475392503557,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1314.0232221095907,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1336.7690022474703,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 5849.577527438578,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 11451.735962983657,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 55860.85563413902,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 552.9212771106614,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2443.2056505524215,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 4782.824013487375,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 23643.967961304745,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 5709.111540962861,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 102148.05094858304,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 394280.0124257282,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2566.42011076275,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "4cdefecfaaf466be728b74af7d411b93cf060ad2",
          "message": "part 1d ongoing",
          "timestamp": "2026-06-25T21:04:30Z",
          "tree_id": "4043c76d64a4fbc7f2f2bbaf2686aab65faf7d31",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/4cdefecfaaf466be728b74af7d411b93cf060ad2"
        },
        "date": 1782421755334,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 21.82631522292013,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 23.757273934856492,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 23.575838461082597,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 26.6563268629706,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 21.993921315953603,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 23.31663361733275,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 23.94874471799488,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 26.904659429310804,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 126.07821520601134,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 497.35913721695545,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 958.8264507858865,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 4664.441307089105,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 543.2069058576047,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1116.7977597798692,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 3324.2272989971166,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 5510.291044633515,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 23900.409571164928,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 375.0352834512885,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 1269.6127616056613,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 2419.477503627095,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 11343.69205215647,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 5091.091226621154,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 55894.51411603048,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 167543.30973029477,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 24.74258721782535,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "386ce0536bfb44dfd02d3980b8bcad3fbc91597f",
          "message": "part2 ex1 complete",
          "timestamp": "2026-06-26T20:59:54Z",
          "tree_id": "abb6aa074e236bd597436675750d6740c1fae97d",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/386ce0536bfb44dfd02d3980b8bcad3fbc91597f"
        },
        "date": 1782507874994,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 16.99186619647295,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 17.572341899716196,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 17.985662345546313,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 19.88553258125215,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 17.077989246625645,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 17.930933315217715,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 17.986556850726068,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 20.25018300250976,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 103.11715826988599,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 447.3481285491925,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 855.4587436876691,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 4346.592617441425,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 440.557236015437,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 74.69395693535887,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 74.6170318453278,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 74.81586970428704,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 74.60409933233068,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 45.25252926903432,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 45.847960234398656,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 45.223368851746756,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 45.255233681228404,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 887.6973991485437,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 2082.312229531919,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 3559.6695548792645,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 17.9459278592676,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "fd5687b86fa791114d109095e58aa78aed2380dd",
          "message": "part2 ex2",
          "timestamp": "2026-06-29T21:59:10Z",
          "tree_id": "330fe43e0e2714aa16e76312c2f3ba8110a19567",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/fd5687b86fa791114d109095e58aa78aed2380dd"
        },
        "date": 1782770645402,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 21.855340228832187,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 22.966663860272547,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 24.448311607737736,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 27.477738425942196,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 22.38037781390476,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 23.68156355664833,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 23.830456938293647,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 26.390566183719496,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 133.7038003733469,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 542.206727916245,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1050.2079598229695,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 4732.787572144854,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 544.1213584968904,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 99.90355104000469,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 99.92413363282175,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 99.93711824042066,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 99.91650831336229,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 58.81834838231499,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 62.59341613340651,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 61.610143545440586,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 58.57078691534986,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 1111.5248791810038,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 2807.7092216659744,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 4813.249570482531,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 25.368890206806157,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "81c7339cacc70ea618bd110b70afbf3bd374f544",
          "message": "second week main completion",
          "timestamp": "2026-06-30T20:56:46Z",
          "tree_id": "77f75a75e854d35d8cf5fa5e16190d4361064878",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/81c7339cacc70ea618bd110b70afbf3bd374f544"
        },
        "date": 1782853252629,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 24.43292094351629,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 25.83912964072208,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 26.200122784022206,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 29.793435868700673,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 26.50675257857226,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 28.21576314348043,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 27.619462670765248,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 30.775432163386963,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 140.80361150774445,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 560.4360386496115,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1087.523315851967,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 5360.13908854099,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 570.187251016848,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 105.38512945715262,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 105.47661980278532,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 104.50636608924587,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 104.3303653778718,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 63.41214958508723,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 63.424976715172924,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 63.415611268093876,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 63.45813705727888,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 1070.9645916715788,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 2784.2085726403843,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 4910.539768649697,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 28.671974932976852,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "115841955+BenFukuzawa@users.noreply.github.com",
            "name": "BenFukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "3e878b7721011a73233cc5bdea2a6aaad04aec45",
          "message": "Merge branch 'jane-street-immersion-program:main' into main",
          "timestamp": "2026-07-01T09:10:12-04:00",
          "tree_id": "04cd70a6d4ec05a6f5f80dcc31b9483c04f5c465",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/3e878b7721011a73233cc5bdea2a6aaad04aec45"
        },
        "date": 1782911639792,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 23.2577277576125,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 24.686431948858495,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 24.53143294515267,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 27.189693517025955,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 22.642293846531278,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 23.87040873886097,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 24.473278053305343,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 27.510195836724435,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 133.9191256096085,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 540.7973060911664,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1048.028132537541,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 4669.781701737623,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 546.9723789802539,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 104.25859063350985,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 104.31434382069105,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 104.76882839790132,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 103.05400900557844,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 60.80684208486159,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 60.725745799219695,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 58.11223050727621,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 59.18323226291001,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 1107.802114079574,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 2737.132791534493,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 4854.854088767544,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 25.433846516763346,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "committer": {
            "email": "ben.fukuzawa@gmail.com",
            "name": "Benjamin Fukuzawa",
            "username": "BenFukuzawa"
          },
          "distinct": true,
          "id": "2e2f04710aa1349e0d549025736830d764d416ea",
          "message": "claude added",
          "timestamp": "2026-07-01T15:30:49Z",
          "tree_id": "848d0b4e6efd1442c98add57943b272db53036dc",
          "url": "https://github.com/BenFukuzawa/jsip-exchange/commit/2e2f04710aa1349e0d549025736830d764d416ea"
        },
        "date": 1782920096025,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 27.589547736274067,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 28.006865379606687,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 28.10627993579013,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 31.133174304382575,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 26.57721688228048,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 26.495696818406408,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 26.852448952253845,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 28.62086714717957,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 151.59079277955365,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 624.8685257263444,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1238.7000215823778,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 6172.656825000304,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 565.5084490618574,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 110.35827785123763,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 110.767357799328,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 111.80134184706601,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 108.31926629686477,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 65.96862139384278,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 64.71452103588666,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 65.30023440501316,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 64.90761859771347,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 1118.5675851002452,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 2920.536210861264,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 5204.816473956909,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 29.190050650947292,
            "unit": "ns"
          }
        ]
      }
    ]
  }
}