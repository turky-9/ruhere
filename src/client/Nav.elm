module Nav exposing (view)

import Html

view: Html.Html msg
view = Html.div []
    [ Html.span [] [ Html.text "Home" ]
    , Html.span [] [ Html.text "Hell" ]
    , Html.span [] [ Html.text "Under Construction" ]
    ]
