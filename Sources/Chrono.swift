//
//  Chrono.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

public enum OptionType: String { case
    morning = "morning",
    afternoon = "afternoon",
    evening = "evening",
    noon = "noon",
    forwardDate = "forwardDate"
}

public struct Chrono {
    /// iOS's Calender.Component to date that has 6 minutes less if the date is before 1900 (compared to JavaScript or Java)
    /// If your use case will include both be ealier than 1900 and its minutes, seconds, nanoseconds, (milliseconds)
    /// you should turn on this fix.
    public static var sixMinutesFixBefore1900 = false
    
    /// In some cases, a keyword for a langugage A means week, for language B could be a non-date related word.
    /// To prevent from getting conflict with other languages, we can simply set the preferred language.
    /// The idead is that if there are at least a reasult generated by the preferred language parser, the parsing will end without
    /// iterating via other languages parser. Otherwise, all parsers will be used in the parsing execution.
    public static var preferredLanguage: Language? = nil
    public static var excludedLanguages: [Language] = []

    /// you can set default imply hour
    public static var defaultImpliedHour: Int = 12
    /// you can set default imply minute
    public static var defaultImpliedMinute: Int = 0
    /// you can set default imply second
    public static var defaultImpliedSecond: Int = 0
    /// you can set default imply millisecond
    public static var defaultImpliedMillisecond: Int = 0
    
    let modeOption: ModeOptio
    var parsers: [Parser] { return modeOption.parsers }
    var refiners: [Refiner] { return modeOption.refiners }
    
    public init(modeOption: ModeOptio = casualModeOption()) {
        self.modeOption = modeOption
    }
    
    public func parse(text: String, refDate: Date = Date(), opt: [OptionType: Int] = [:]) -> [ParsedResult] {
        var allResults = [ParsedResult]()
        
        if text.isEmpty {
            return allResults
        }
        
        if let lang = Chrono.preferredLanguage {
            // first phase: preferredLanguage parsers
            for parser in parsers {
                if Chrono.excludedLanguages.contains(parser.language) {
                    continue
                }
                if parser.language == .english || parser.language == lang {
                    allResults += parser.execute(text: text, ref: refDate, opt: opt)
                }
            }
            
            // second phase: other language parsers
            if allResults.isEmpty {
                for parser in parsers {
                    if parser.language != .english && parser.language != lang {
                        allResults += parser.execute(text: text, ref: refDate, opt: opt)
                    }
                }
            }
        } else {
            for parser in parsers {
                if Chrono.excludedLanguages.contains(parser.language) {
                    continue
                }
                allResults += parser.execute(text: text, ref: refDate, opt: opt)
            }
        }
        
        allResults.sort { $0.index < $1.index }
        
        for refiner in refiners {
            allResults = refiner.refine(text: text, results: allResults, opt: opt)
        }
        
        return allResults
    }
    
    public func parseDate(text: String, refDate: Date = Date(), opt: [OptionType: Int] = [:]) -> Date? {
        let results = Chrono.casual.parse(text: text, refDate: refDate, opt: opt)
        return results.first?.start.date
    }
    
    public static let strict = Chrono(modeOption: strictModeOption())
    public static let casual = Chrono(modeOption: casualModeOption())
}
