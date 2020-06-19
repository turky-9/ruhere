port module Main exposing (main)

-- import Browser.Navigation as Navigation

import Browser
import Debug
import Html
import Html.Attributes as Attributes
import Html.Events as Events
import Nav exposing (..)
import Pages.Status as PageStatus
import Url



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


type Msg
    = Msg
    | MsgToJs
    | MsgFromJs String
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
init _ =
    ( ModelStatus PageStatus.init, Cmd.none )


-- ############################################################################
-- ports
-- ############################################################################
port toJs : String -> Cmd msg
port fromJs : (String -> msg) -> Sub msg

-- ############################################################################
-- subscriptions
-- ############################################################################


subscriptions : Model -> Sub Msg
subscriptions _ =
    fromJs MsgFromJs



-- ############################################################################
-- update
-- ############################################################################


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        debug =
            Debug.toString msg ++ " : " ++ Debug.toString model
    in
    case ( msg, model ) of
        ( MsgStatus subMsg, ModelStatus subModel ) ->
            Debug.log ("@Main.update: " ++ debug) PageStatus.update subMsg subModel |> sub2MainUpdate ModelStatus MsgStatus

        ( MsgToJs, _ ) ->
            ( model, toJs "from Elm to Js" )

        ( MsgFromJs s, _ ) ->
            ( model, Cmd.none ) |> Debug.log("from js: " ++ s)

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            Debug.log ("update _: " ++ debug) ( model, Cmd.none )



{-
   サブモデルとサブメッセージからMainのモデルとメッセージに変換
-}


sub2MainUpdate : (subModel -> Model) -> (subMsg -> Msg) -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
sub2MainUpdate toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- ############################################################################
-- view
-- ############################################################################


view : Model -> Html.Html Msg
view model =
    case model of
        {-
           Mainのモデルからサブモデルにパターンマッチ
        -}
        ModelStatus stat ->
            Debug.log ("@Main.view: " ++ Debug.toString model)
                Html.div
                [ Attributes.class "hoge" ]
                [ Html.div []
                    [ Html.button [ Events.onClick MsgToJs ] [Html.text "to Js"]]
                , Nav.view
                , PageStatus.view stat |> sub2MainView MsgStatus
                ]



{-
   サブメッセージからMainのメッセージに変換
-}


sub2MainView : (a -> Msg) -> Html.Html a -> Html.Html Msg
sub2MainView toMsg html =
    Html.map toMsg html



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
