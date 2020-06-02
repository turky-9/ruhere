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
    | MsgGotReload (Result Http.Error Dept)

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
            Debug.log "@Status.update MsgReload"
            ( model, Http.post
                 { url =  "http://localhost:4486/api/refresh"
                 , body = Http.emptyBody
                 , expect = Http.expectJson MsgGotReload deptDecoder
                 }
            )
        MsgGotReload result ->
            case result of
                Ok dept ->
                    Debug.log ("@Status.update MsgGotReload Ok: " ++ Debug.toString dept) ( dept, Cmd.none )
                Err err ->
                    Debug.log ("@Status.update MsgGotReload Err: " ++ Debug.toString err) ( model, Cmd.none )


view : Model -> Html.Html Msg
view model = Html.div [ Attributes.style "display" "flex" ]
        [ Html.div []
            [ Html.button [ Events.onClick MsgReload ] [ Html.text "Reload" ]
            , renderDept model
            ]
        , Html.div [ ] [ renderUsers model.users ]
        ]


renderDept : Dept -> Html.Html msg
renderDept dept = Html.ul []
    [ Html.li [] [ Html.text dept.name ]
    ]

renderUsers : List User -> Html.Html msg
renderUsers users = Html.table []
    (Html.tr []
        [ Html.td [] [ Html.text "名前" ]
        , Html.td [] [ Html.text "状態" ]
        ]
    :: (List.map renderUser users))

renderUser : User -> Html.Html msg
renderUser user = Html.tr []
    [ Html.td [] [ Html.text user.name]
    , Html.td [] [ Html.text (displayStatus user.status)]
    ]

displayStatus : EStatus -> String
displayStatus stat =
    case stat of
        Here -> "Here"
        Out -> "Out"
        Meeting -> "Meeting"


deptDecoder : Decode.Decoder Dept
deptDecoder = Decode.map3 Dept
    (Decode.field "name" Decode.string)
    (Decode.field "users" (Decode.list userDecoder))
    -- (Decode.field "children" (Decode.map Depts (Decode.list (Decode.lazy (\_ -> deptDecoder)))))
    ((\_ -> deptDecoder) |> Decode.lazy |> Decode.list |> Decode.map Depts |> Decode.field "children")

userDecoder : Decode.Decoder User
userDecoder = Decode.map2 User
    (Decode.field "name" Decode.string)
    (Decode.field "status" statusDecoder)

statusDecoder : Decode.Decoder EStatus
statusDecoder =
    Decode.string
        |> Decode.andThen (\str ->
            case str of
                "Here" ->
                    Decode.succeed Here
                x ->
                    Decode.fail <| "Unknown Status" ++ x
        )