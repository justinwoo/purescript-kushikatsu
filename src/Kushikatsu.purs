module Kushikatsu where

import Prelude

import Data.Either (Either(..))
import Data.Newtype (class Newtype)
import Data.Variant (Variant)
import Data.Variant as Variant
import Kushiyaki as K
import Prim.Row as Row
import Prim.RowList as RL
import Type.Prelude (class IsSymbol, RLProxy(..), SProxy(..))

type RouteURL = SProxy

newtype NoMatch = NoMatch String
derive instance newtypeNoMatch :: Newtype NoMatch _

matchRoutes
  :: forall proxy routes routesL var
   . RL.RowToList routes routesL
  => RoutesLToVariant routesL var
  => proxy routes
  -> String
  -> Either NoMatch (Variant var)
matchRoutes _ = routesLToVariant (RLProxy :: RLProxy routesL)

class RoutesLToVariant
  (routesL :: RL.RowList)
  (var :: # Type)
  | routesL -> var
  where
    routesLToVariant
      :: RLProxy routesL
      -> String
      -> Either NoMatch (Variant var)

instance nilRoutesToVariant :: RoutesLToVariant RL.Nil ()
  where
    routesLToVariant _ s = Left (NoMatch s)

instance consRoutesToVariant ::
  ( K.ParseURL url row
  , IsSymbol rName
  , RoutesLToVariant rTail var'
  , Row.Cons rName { | row } var' var
  , Row.Union var' var'' var
  ) => RoutesLToVariant
         (RL.Cons rName (SProxy url) rTail)
         var
  where
    routesLToVariant _ s =
      case K.parseURL (SProxy :: SProxy url) s of
        Right (r :: { | row }) ->
          Right $ Variant.inj (SProxy :: SProxy rName) r
        Left l ->
          Variant.expand <$> routesLToVariant (RLProxy :: RLProxy rTail) s
