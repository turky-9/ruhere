module Pages.Status exposing (init, view, update, Msg, Model)

import Html
import Html.Attributes as Attributes
import Html.Events as Events
import Http
import Json.Decode as Decode
import Debug

type EStatus = Out
    | Here
    | Meeting

type alias User =
    { name: String
    , status: EStatus
    }

type alias Dept =
    { name: String
    , users: List User
    , children: Depts
    }
type Depts = Depts (List Dept)

type alias Model = Dept

type Msg
    = MsgReload
    | MsgGotReload (Result Http.Error String)

init : Dept
init =
    { name = "Init"
    , users = []
    , children = Depts []
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        MsgReload ->
            ( model, Http.post
                 { url = (Debug.log "update2 MsgReload" "http://localhost:4486/api/refresh")
                 , body = Http.emptyBody
                 , expect = Http.expectJson MsgGotReload decodeReload
                 }
            )
        MsgGotReload _ ->
            ( model, Cmd.none )

view: Html.Html Msg
view = Html.div [ Attributes.style "display" "flex" ]
    [ Html.div [ ]
        [ Html.button [ Events.onClick MsgReload ] [ Html.text "Reload" ]
        ]
    , Html.div [ ] [ Html.text "bbb" ]
    ]


decodeReload : Decode.Decoder String
decodeReload = Decode.field "name" Decode.string
