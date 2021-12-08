module Routing exposing (..)

import Browser
import Browser.Navigation as Nav
import Common
import Page exposing (Page(..))
import Ports
import Radix
import Return exposing (return)
import Share.Accept.Progress
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 📣


goToPage : Page -> Radix.Manager
goToPage page model =
    [ case model.page of
        Page.LinkAccount _ ->
            -- When moving away from the link-account page,
            -- make sure to close the secure channel.
            Ports.closeChannel ()

        _ ->
            Cmd.none

    --
    , case page of
        Page.CreateAccount _ ->
            Common.focus Radix.Bypassed "email"

        Page.LinkAccount _ ->
            Common.focus Radix.Bypassed "username"

        _ ->
            Cmd.none
    ]
        |> Cmd.batch
        |> return { model | page = page }


urlChanged : Url -> Radix.Manager
urlChanged url model =
    let
        page =
            url
                |> fromUrl
                |> Maybe.withDefault model.page
    in
    Return.singleton { model | page = page, url = url }


urlRequested : Browser.UrlRequest -> Radix.Manager
urlRequested request model =
    case request of
        Browser.Internal url ->
            return model (Nav.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Nav.load href)



-- 🔮


fromUrl : Url -> Maybe Page
fromUrl url =
    Url.parse route { url | path = Maybe.withDefault "" url.fragment }


route : Parser (Page -> a) a
route =
    oneOf
        [ map
            (\sharedBy shareId ->
                AcceptShare
                    { progress = Share.Accept.Progress.Preparing
                    , shareId = shareId
                    , sharedBy = sharedBy
                    }
            )
            (s "share" </> string </> string)
        ]
