window.BENCHMARK_DATA = {
  "lastUpdate": 1781724534924,
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
      }
    ]
  }
}