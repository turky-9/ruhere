module Pages.Status exposing (Model, Msg, init, update, view)

import Debug
import Html
import Html.Attributes as Attributes
import Html.Events as Events
import Http
import Json.Decode as Decode


type EStatus
    = Out
    | Here
    | Meeting


type alias User =
    { name : String
    , status : EStatus
    }


type alias Dept =
    { name : String
    , users : List User
    , children : Depts
    }


type Depts
    = Depts (List Dept)


type alias Model =
    Dept


type Msg
    = MsgReload
    | MsgGotReload (Result Http.Error Dept)


init : Dept
init =
    { name = "Init"
    , users = []
    , children = Depts []
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MsgReload ->
            Debug.log "@Status.update MsgReload"
                ( model
                , Http.post
                    { url = "http://localhost:4486/api/refresh"
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



-- ############################################################################
-- view
-- ############################################################################


view : Model -> Html.Html Msg
view model =
    Html.div [ Attributes.style "display" "flex" ]
        [ Html.div []
            [ Html.button [ Events.onClick MsgReload ] [ Html.text "Reload" ]
            , renderDept model
            ]
        , Html.div [] [ renderUsers model.users ]
        ]


renderDept : Dept -> Html.Html msg



-- renderDept dept =
--     Html.ul []
--         [ Html.li []
--             ( Html.text dept.name
--             :: [ Html.ul [] (List.map renderChildDept (getListDept dept.children)) ]
--             )
--         ]


renderDept dept =
    let
        template : String -> Html.Html msg -> List (Html.Html msg) -> Html.Html msg
        template self child bro =
            Html.ul []
                (Html.li []
                    (Html.text self :: [ child ])
                    :: bro
                )
    in
    Html.ul []
        [ Html.li [] [ Html.text dept.name ]
        ]


renderDeptChildren : List Dept -> Html.Html msg
renderDeptChildren depts =
    case depts of
        x :: xs ->
            Html.li [] [ Html.text x.name ]

        [] ->
            Html.text ""


getListDept : Depts -> List Dept
getListDept d =
    case d of
        Depts x ->
            x


renderChildDept : Dept -> Html.Html msg
renderChildDept child =
    Html.li [] [ Html.text child.name ]


renderUsers : List User -> Html.Html msg
renderUsers users =
    Html.table []
        (Html.tr []
            [ Html.td [] [ Html.text "名前" ]
            , Html.td [] [ Html.text "状態" ]
            ]
            :: List.map renderUser users
        )


renderUser : User -> Html.Html msg
renderUser user =
    Html.tr []
        [ Html.td [] [ Html.text user.name ]
        , Html.td [] [ Html.text (displayStatus user.status) ]
        ]


displayStatus : EStatus -> String
displayStatus stat =
    case stat of
        Here ->
            "Here"

        Out ->
            "Out"

        Meeting ->
            "Meeting"


deptDecoder : Decode.Decoder Dept
deptDecoder =
    Decode.map3 Dept
        (Decode.field "name" Decode.string)
        (Decode.field "users" (Decode.list userDecoder))
        -- (Decode.field "children" (Decode.map Depts (Decode.list (Decode.lazy (\_ -> deptDecoder)))))
        ((\_ -> deptDecoder) |> Decode.lazy |> Decode.list |> Decode.map Depts |> Decode.field "children")


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map2 User
        (Decode.field "name" Decode.string)
        (Decode.field "status" statusDecoder)


statusDecoder : Decode.Decoder EStatus
statusDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "Here" ->
                        Decode.succeed Here

                    "Out" ->
                        Decode.succeed Out

                    "Meeting" ->
                        Decode.succeed Meeting

                    x ->
                        Decode.fail <| "Unknown Status" ++ x
            )
