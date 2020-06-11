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

type alias RenderingUser =
    { deptName : String
    , user: User
    }


type alias Dept =
    { name : String
    , users : List User
    , children : Depts
    }


type Depts
    = Depts (List Dept)


type alias CurrentDept =
    String


type Model
    = Model Dept CurrentDept


type Msg
    = MsgReload
    | MsgGotReload (Result Http.Error Dept)
    | MsgChangeCurrentDept CurrentDept


init : Model
init =
    Model
        { name = "Init"
        , users = []
        , children = Depts []
        }
        "Init"


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
                    Debug.log ("@Status.update MsgGotReload Ok: " ++ Debug.toString dept) ( Model dept dept.name, Cmd.none )

                Err err ->
                    Debug.log ("@Status.update MsgGotReload Err: " ++ Debug.toString err) ( model, Cmd.none )

        MsgChangeCurrentDept curr ->
            Debug.log ("@Status.update MsgChangeCurrentDept: " ++ Debug.toString curr) ( Model (getDept model) curr, Cmd.none )



-- ############################################################################
-- view
-- ############################################################################


view : Model -> Html.Html Msg
view model =
    case model of
        Model dept curr ->
            Html.div [ Attributes.style "display" "flex" ]
                [ Html.div []
                    [ Html.button [ Events.onClick MsgReload ] [ Html.text "Reload" ]
                    , renderDept [ dept ] curr
                    ]
                , Html.div [] [ renderUsers dept curr ]
                ]


-- ############################################################################
-- renderer
-- ############################################################################
renderDept : List Dept -> CurrentDept -> Html.Html Msg
renderDept depts curr =
    case depts of
        x :: xs ->
            Html.ul [] (renderDeptChildren depts [] curr)

        [] ->
            Html.text ""


renderDeptChildren : List Dept -> List (Html.Html Msg) -> CurrentDept -> List (Html.Html Msg)
renderDeptChildren depts result curr =
    case depts of
        x :: xs ->
            renderDeptChildren xs
                (Html.li []
                    [ Html.span
                        [ Events.onClick (MsgChangeCurrentDept x.name)
                        , Attributes.classList [("curr-dept", x.name == curr)]
                        ]
                        [ Html.text x.name ]
                    , renderDept (getListDept x.children) curr
                    ]
                    :: result
                )
                curr

        [] ->
            List.reverse result


renderUsers : Dept -> CurrentDept -> Html.Html msg
renderUsers top curr =
    let
        dept = searchCurrentDept top curr
        users = (case dept of
            Just x -> getFlatUserList [x]
            Nothing -> [])
                |> Debug.log ("@Status.renderUsers: current is " ++ curr ++ " and found is " ++ (Debug.toString dept))
    in
    Html.table []
        (Html.tr []
            [ Html.td [] [ Html.text "部署" ]
            , Html.td [] [ Html.text "名前" ]
            , Html.td [] [ Html.text "状態" ]
            ]
            :: List.map (renderUser curr) users
        )


renderUser : String -> User -> Html.Html msg
renderUser dept user =
    Html.tr []
        [ Html.td [] [ Html.text dept ]
        , Html.td [] [ Html.text user.name ]
        , Html.td [] [ Html.text (displayStatus user.status) ]
        ]


-- ############################################################################
-- utils
-- ############################################################################
getFlatUserList : List Dept -> List User
getFlatUserList depts =
    case depts of
        x :: xs ->
            x.users ++ (getFlatUserList (getListDept x.children)) ++ (getFlatUserList xs)
        [] ->
            []

searchCurrentDept : Dept -> CurrentDept -> Maybe Dept
searchCurrentDept dept curr =
    let
        findChildren : List Dept -> Maybe Dept
        findChildren depts =
            case depts of
                x :: xs ->
                    let
                        result = searchCurrentDept x curr
                    in
                    case result of
                        Just _ -> result
                        Nothing -> findChildren xs
                [] -> Nothing
    in
    (
    if dept.name == curr then
        Just dept
    else
        getListDept dept.children |> findChildren
    )
    |> Debug.log ("@Status.searchCurrentDept: " ++ dept.name ++ " : " ++ curr)

getRenderingUser : Dept -> List RenderingUser
getRenderingUser dept = []


displayStatus : EStatus -> String
displayStatus stat =
    case stat of
        Here ->
            "Here"

        Out ->
            "Out"

        Meeting ->
            "Meeting"

getListDept : Depts -> List Dept
getListDept d =
    case d of
        Depts x ->
            x


getDept : Model -> Dept
getDept model =
    case model of
        Model d c ->
            d

-- ############################################################################
-- decoder
-- ############################################################################
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
