//
//  PerformanceTimer.swift
//  day13
//
//  Created on 11/10/25.
//

import Foundation

/// 성능 측정 유틸리티
final class PerformanceTimer {
    private var startTime: CFAbsoluteTime = 0
    private var measurements: [String: [Double]] = [:]
    
    /// 타이머 시작
    func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    /// 타이머 종료 및 경과 시간 반환 (밀리초)
    func stop() -> Double {
        let endTime = CFAbsoluteTimeGetCurrent()
        return (endTime - startTime) * 1000.0
    }
    
    /// 레이블과 함께 측정값 기록
    func record(label: String, time: Double) {
        if measurements[label] == nil {
            measurements[label] = []
        }
        measurements[label]?.append(time)
    }
    
    /// 레이블의 평균 시간 계산
    func average(for label: String) -> Double? {
        guard let times = measurements[label], !times.isEmpty else {
            return nil
        }
        return times.reduce(0, +) / Double(times.count)
    }
    
    /// 모든 측정값 초기화
    func reset() {
        measurements.removeAll()
    }
    
    /// 통계 요약 출력
    func printSummary() {
        print("📊 성능 측정 요약:")
        for (label, times) in measurements.sorted(by: { $0.key < $1.key }) {
            let avg = times.reduce(0, +) / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0
            print("  \(label):")
            print("    평균: \(String(format: "%.2f", avg)) ms")
            print("    최소: \(String(format: "%.2f", min)) ms")
            print("    최대: \(String(format: "%.2f", max)) ms")
            print("    횟수: \(times.count)")
        }
    }
}

