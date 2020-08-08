import Flutter
import UIKit
import PaperTrailLumberjack

extension DDLogFlag {
    static func fromString(_ logLevelString: String) -> DDLogFlag {
        switch logLevelString {
        case "error":
            return DDLogFlag.error
        case "warning":
            return DDLogFlag.warning
        case "info":
            return DDLogFlag.info
        case "debug":
            return DDLogFlag.debug
        default:
            return DDLogFlag.info
        }
    }
}

public class SwiftFlutterPaperTrailPlugin: NSObject, FlutterPlugin {
    private static var programName: String?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_paper_trail", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPaperTrailPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "initLogger" {
            self.setupLoggerAndParseArguments(call, result: result)
        }else if call.method == "setUserId" {
            self.configureUserAndParseArguments(call, result: result)
        }else if call.method == "log"{
            logMessageAndParseArguments(call, result: result)
        }else{
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func configureUserAndParseArguments(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let params = call.arguments as? Dictionary<String,String> else {
            result(FlutterError(code: "Missing arguments", message: nil, details: nil))
            return
        }
        
        guard let userId = params["userId"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing userId", details: nil))
            return
        }
        guard let _ = RMPaperTrailLogger.sharedInstance()?.programName else{
            result(FlutterError(code: "Cannot call configure user before init logger", message: nil, details: nil))
            return
        }
        let paperTrailLogger = RMPaperTrailLogger.sharedInstance()!
        paperTrailLogger.programName = userId + "--on--" + SwiftFlutterPaperTrailPlugin.programName!
        result("Logger updated")
    }
    
    
    private func logMessageAndParseArguments(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let params = call.arguments as? Dictionary<String,String> else {
            result(FlutterError(code: "Missing arguments", message: "Missing userId", details: nil))
            return
        }
        
        guard let message = params["message"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing message", details: nil))
            return
        }
        guard let logLevelString = params["logLevel"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing logLevel", details: nil))
            return
        }
        let flag = DDLogFlag.fromString(logLevelString)
        let logMessage = DDLogMessage(
            message: message,
            level: dynamicLogLevel,
            flag: flag,
            context: 0,
            file: "",
            function: "",
            line: 0,
            tag: nil,
            options: [],
            timestamp: nil)
        DDLog.sharedInstance.log(asynchronous: true, message: logMessage)

        result("logged")
    }
    
    
    private func setupLoggerAndParseArguments(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let params = call.arguments as? Dictionary<String,String> else {
            result(FlutterError(code: "Missing arguments", message: nil, details: nil))
            return
        }
        
        guard let hostName = params["hostName"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing hostName", details: nil))
            return
        }
        guard let programNameParam = params["programName"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing programName", details: nil))
            return
        }
        guard let machineName = params["machineName"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing machineName", details: nil))
            return
        }
        
        guard let portString = params["port"] else {
            result(FlutterError(code: "Missing arguments", message: "Missing port", details: nil))
            return
        }
        guard let port = UInt(portString) else{
            result(FlutterError(code: "Missing arguments", message: "port is not int", details: nil))
            return
        }
        
        let paperTrailLogger = RMPaperTrailLogger.sharedInstance()!
        paperTrailLogger.host = hostName
        paperTrailLogger.port = port
        
        SwiftFlutterPaperTrailPlugin.programName = programNameParam
        paperTrailLogger.programName = SwiftFlutterPaperTrailPlugin.programName
        paperTrailLogger.machineName = machineName
        DDLog.add(paperTrailLogger)
        
        result("Logger initialized")
    }
}
