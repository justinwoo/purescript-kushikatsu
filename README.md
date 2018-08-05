# PureScript-Kushikatsu

Simple routing with [Kushiyaki](https://github.com/justinwoo/purescript-kushiyaki).

Wrapped kushiyaki is kushikatsu:

![](https://i.imgur.com/GC18feC.jpg)

Requires PureScript 0.12

## Usage

Setup:

```hs
type RouteURLs =
  ( hello :: RouteURL "/hello/{name}"
  , age :: RouteURL "/age/{age:Int}"
  , answer :: RouteURL "/gimme/{item:String}/{count:Int}"
  )

main :: Effect Unit
main = do
  let snoc' a xs = Array.snoc xs a
  ref <- Ref.new []

  let
    -- inferred type:
    -- (matchRoutes' :: String
    --     -> Either
    --          NoMatch
    --          (Variant
    --             ( hello :: { name :: String}
    --             , age :: { age :: Int }
    --             , answer :: { item :: String , count :: Int }
    --             )
    --         )
    -- ) =
    matchRoutes' =
      matchRoutes (RProxy :: RProxy RouteURLs)

    testRoutes =
      [ "/hello/Bill"
      , "/age/12"
      , "/gimme/Apple/24"
      , "/no/match"
      ]

    matched = matchRoutes' <$> testRoutes
    handleResult = case _ of
      Left (NoMatch l) -> do
        Ref.modify_ (snoc' $ "no match: " <> l) ref
      Right r ->
        Variant.match
          { hello: \x -> Ref.modify_ (snoc' x.name) ref
          , age: \x -> Ref.modify_ (snoc' $ show x.age) ref
          , answer: \x ->  Ref.modify_ (snoc' $ show x.count <> "," <> x.item) ref
          }
          r

  traverse_ handleResult matched

  actual <- Ref.read ref
  let
    expected =
      [ "Bill"
      , "12"
      , "24,Apple"
      , "no match: /no/match"
      ]
  assertEqual { actual, expected }
```
