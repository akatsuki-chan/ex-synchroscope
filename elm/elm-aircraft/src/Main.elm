port module Aircraft exposing (..)

import Mouse
import Keyboard
import WebSocket
import VirtualDom exposing (Node, programWithFlags)
import Json.Encode as JE exposing (int, string, list, encode, object)
import Json.Decode as JD exposing ((:=), decodeString, andThen)

import Native.XPath

-- MODEL
type alias Model = {
  mode: Maybe Int,
  url: String
}

init : AppConfig -> (Model, Cmd Msg)
init config = ({ mode = Just config.mode, url = getUrl config}, Cmd.none)

-- MESSAGES
type Msg
    = Mouse Mouse.Position
    | Key Keyboard.KeyCode
    | Accept String
    | Element String
    | Dom JD.Value
    | Fire (JD.Value, JD.Value)

-- VIEW
view : Model -> Node a
view model = VirtualDom.text ""

-- UPDATE
type EventJson = PositionEvent Int Int | CodeEvent Int | ElementEvent String | XPathEvent String | FiredEvent String String String


port recvHandler: JE.Value -> Cmd msg
port getElement: (Int, Int) -> Cmd a

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Mouse position ->
            (model, getElement (position.x, position.y))
        Key code ->
            (model, WebSocket.send model.url (codeToJson code))
        Accept raw ->
            case decodeString decodeEvent raw of
              Ok (PositionEvent x y) ->
                (model, recvHandler (object [("event", string "position"), ("x", int x), ("y", int y)]))
              Ok (CodeEvent code) ->
                (model, recvHandler (object [("event", string "code"), ("code", int code)]))
              Ok (ElementEvent id) ->
                (model, recvHandler (object [("event", string "element"), ("id", string id)]))
              Ok (XPathEvent path) ->
                (model, recvHandler (object [("event", string "path"), ("path", string path)]))
              Ok (FiredEvent target value eventType) ->
                (model, recvHandler (object [("event", string "event"), ("target", string target), ("value", string value)]))
              Err _ -> (model, Cmd.none)
        Element id ->
            (model, WebSocket.send model.url (elementToJson id))
        Dom dom ->
            (model, WebSocket.send model.url (xpathToJson (Native.XPath.getXPath dom)))
        Fire (target, info) ->
            (model, WebSocket.send model.url (eventToJson (Native.XPath.getXPath target) info))


-- SUBSCRIPTIONS

port detectElement: (String -> a) -> Sub a
port elementXPath: (JD.Value -> a) -> Sub a
port fireFormEvent: ((JD.Value, JD.Value) -> a) -> Sub a

subscriptions : Model -> Sub Msg
subscriptions model =
  case model.mode of
    Just 1 ->
      Sub.batch
          [ Mouse.clicks Mouse
          -- , Mouse.moves Mouse
          , Keyboard.presses Key
          , detectElement Element
          , elementXPath Dom
          , fireFormEvent Fire
          , WebSocket.listen model.url Accept]
    Just 0 ->
      WebSocket.listen model.url Accept
    _ -> Sub.none

-- MAIN

type alias AppConfig = {
    mode: Int
  , url: Maybe String
}

getUrl : AppConfig -> String
getUrl config =
  case config.url of
    Nothing -> "ws://127.0.0.1:8080/"
    Just x -> x


main : Program AppConfig
main =
    VirtualDom.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

-- INTERNAL
elementToJson : String -> String
elementToJson id =
  encode 0 (object [("event", string "element"), ("id", string id)])

positionToJson : Mouse.Position -> String
positionToJson position =
  encode 0 (object [("event", string "position"), ("x", int position.x), ("y", int position.y)])

codeToJson : Int -> String
codeToJson code =
  encode 0 (object [("event", string "code"), ("code", int code)])

xpathToJson : String -> String
xpathToJson path =
  encode 0 (object [("event", string "path"), ("path", string path)])

type EventInfo = EventInfo String String Bool

eventToJson: String -> JD.Value -> String
eventToJson target option =
  let 
    decoder = 
      JD.object3 EventInfo ("value" := JD.string) ("type" := JD.string) ("checked" := JD.bool)
  in
  encode 0 (object [
    ("event", string "event"), 
    ("target", string target),
    ("info", option)])

decodeEvent : JD.Decoder EventJson
decodeEvent =
  let
    eventInfo ev =
      case ev of
        "position" ->
          JD.object2 PositionEvent ("x" := JD.int) ("y" := JD.int)
        "code" ->
          JD.object1 CodeEvent ("code" := JD.int)
        "element" ->
          JD.object1 ElementEvent ("id" := JD.string)
        "path" ->
          JD.object1 XPathEvent ("path" := JD.string)
        "event" ->
          JD.object3 FiredEvent ("target" := JD.string) (JD.at ["info", "value"] JD.string) (JD.at ["info", "event_type"] JD.string)

        _ -> JD.fail "parse error"
  in ("event" := JD.string) `andThen` eventInfo
