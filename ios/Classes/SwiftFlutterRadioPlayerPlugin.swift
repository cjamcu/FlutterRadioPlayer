import Flutter
import UIKit

public class SwiftFlutterRadioPlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
  private var streamingCore: StreamingCore = StreamingCore()
  
  private var mEventSink: FlutterEventSink?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "flutter_radio_player", binaryMessenger: registrar.messenger())
      let instance = SwiftFlutterRadioPlayerPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
      
      // register the event channel
      let eventChannel = FlutterEventChannel(name: "flutter_radio_player_stream", binaryMessenger: registrar.messenger())
      eventChannel.setStreamHandler(instance)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch (call.method) {
      case "initService":
          print("method called to start the radio service")
          if let args = call.arguments as? Dictionary<String, Any>,
              let streamURL = args["streamURL"] as? String,
              let appName = args["appName"] as? String,
              let subTitle = args["subTitle"] as? String,
              let playWhenReady = args["playWhenReady"] as? String
          {
            streamingCore.initService(streamURL: streamURL, serviceName: appName, secondTitle: subTitle, playWhenReady: playWhenReady)
            
              NotificationCenter.default.addObserver(self, selector: #selector(onRecieve(_:)), name: Notifications.playbackNotification, object: nil)
              result(nil)
          }
          break
      case "playOrPause":
          print("method called to playOrPause from service")
          if (streamingCore.isPlaying()) {
              _ = streamingCore.pause()
          } else {
              _ = streamingCore.play()
          }
      case "play":
          print("method called to play from service")
          let status = streamingCore.play()
          if (status == PlayerStatus.PLAYING) {
              result(true)
          }
          result(false)
          break
      case "pause":
          print("method called to play from service")
          let status = streamingCore.pause()
          if (status == PlayerStatus.IDLE) {
              result(true)
          }
          result(false)
          break
      case "stop":
          print("method called to stopped from service")
          let status = streamingCore.stop()
          if (status == PlayerStatus.STOPPED) {
              result(true)
          }
          result(false)
          break
      case "isPlaying":
          print("method called to is_playing from service")
          result(streamingCore.isPlaying())
          break
      case "setVolume":
          print("method called to setVolume from service")
          if let args = call.arguments as? Dictionary<String, Any>,
              let volume = args["volume"] as? NSNumber {
              print("Recieved set to volume: \(volume)")
              streamingCore.setVolume(volume: volume)
          }
          result(nil)
      default:
          result(nil)
      }
  }
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      if (mEventSink == nil) {
          mEventSink = events
      }
      return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      mEventSink = nil
      return nil
  }
  
  @objc private func onRecieve(_ notification: Notification) {
      // unwrapping optional
      if let playerEvent = notification.userInfo!["status"] {
          print("Notification received with event name: \(playerEvent)")
          mEventSink!(playerEvent)
      }
  }
}
