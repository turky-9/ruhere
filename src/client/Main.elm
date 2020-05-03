module Main exposing (main)

import Url
import Browser
-- import Browser.Navigation as Navigation
import Html
import Html.Attributes as Attributes
import Debug

import Nav exposing (..)
import Pages.Status as PageStatus

-- import Route exposing (Route, fromUrl)
-- import Page.Home as Home
-- import Page.Friends as Friends



-- ############################################################################
-- モデル
-- ############################################################################
{-
type alias Session =
    { key : Navigation.Key
    , url : Url.Url
    }
type Model
    = Home Session Home.Model
    | Friends Session Friends.Model
    | NotFound Session
-}
type Model
    = ModelStatus PageStatus.Model



-- ############################################################################
-- フラグ
-- ############################################################################
type alias Flags =
    {}



-- ############################################################################
-- メッセージ
-- ############################################################################
type Msg = Msg
    | MsgStatus PageStatus.Msg
{-
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotHome Home.Msg
    | GotFriends Friends.Msg
-}




-- ############################################################################
-- init
-- ############################################################################
init : Flags -> ( Model, Cmd Msg )
init _ = (ModelStatus PageStatus.init, Cmd.none )



-- ############################################################################
-- subscriptions
-- ############################################################################
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


-- ############################################################################
-- update
-- ############################################################################
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        debug = (Debug.toString msg) ++ " : " ++ (Debug.toString model)
    in
    case (msg, model) of
        ( MsgStatus subMsg, ModelStatus subModel) ->
            PageStatus.update subMsg subModel |> Debug.log ("update1: " ++ debug) |> updateWith  ModelStatus MsgStatus

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            Debug.log ("update _: " ++ debug)  ( model, Cmd.none )

{-
    サブモデルとサブメッセージからMainのモデルとメッセージに変換
-}
updateWith : (subModel -> Model) -> (subMsg -> Msg) -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )

-- ############################################################################
-- view
-- ############################################################################
view : Model -> Html.Html Msg
view model =
    let
        {-
          サブメッセージからMainのメッセージに変換
        -}
        viewPage : (a -> Msg)  -> Html.Html a -> Html.Html Msg
        viewPage toMsg html =  Html.map toMsg html
    in
    case model of
        {-
          Mainのモデルからサブモデルにパターンマッチ
        -}
        _ -> Html.div [ Attributes.class "hoge" ]
             [ Nav.view
             , PageStatus.view |> viewPage MsgStatus
             ]


-- ############################################################################
-- main
-- ############################################################################
main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
