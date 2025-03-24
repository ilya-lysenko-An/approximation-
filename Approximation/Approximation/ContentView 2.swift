//
//  ContentView 2.swift
//  Approximation
//
//  Created by Илья Лысенко on 22.02.2025.
//


import SwiftUI
import Charts

struct ContentView: View {
    @State private var inputX = "" // Ввод для значений X
    @State private var inputY = "" // Ввод для значений Y
    @State private var graphPoints: [(Double, Double)] = [] // Точки для построения графика
    @State private var approximationPoints: [(Double, Double)] = [] // Точки для аппроксимации
    @State private var errorMessage = ""
    @State private var isFullScreen = false // Состояние для отображения графика во весь экран
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Введите значения X и Y:")
                    .font(.headline)
                
                // Поле для ввода значений X
                TextField("Пример:Х = 1 3 5", text: $inputX)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Поле для ввода значений Y
                TextField("Пример:Y = 2 4 6", text: $inputY)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                HStack {
                    Button("Построить график") {
                        parseInput()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Удалить график") {
                        clearGraph()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                if !graphPoints.isEmpty {
                    Chart {
                        ForEach(Array(graphPoints.enumerated()), id: \.offset) { index, point in
                            LineMark(
                                x: .value("X", point.0),
                                y: .value("Y", point.1)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        ForEach(Array(approximationPoints.enumerated()), id: \.offset) { index, point in
                            PointMark(
                                x: .value("X", point.0),
                                y: .value("Y", point.1)
                            )
                            .foregroundStyle(Color.red)
                            .symbolSize(10)
                        }
                    }
                    .frame(height: 300)
                    .padding()
                    .onTapGesture {
                        isFullScreen = true // Открываем график во весь экран при нажатии
                    }
                }
                
                Button("Аппроксимировать") {
                    calculateApproximation()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            // Скрываем клавиатуру при нажатии на экран
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $isFullScreen) {
            FullScreenChartView(graphPoints: graphPoints, approximationPoints: approximationPoints, isFullScreen: $isFullScreen)
        }
    }
    
    // Функция для парсинга ввода
    func parseInput() {
        errorMessage = ""
        graphPoints = []
        approximationPoints = []
        
        // Разделяем ввод X и Y на массивы
        let xValues = inputX.split(separator: " ").compactMap { Double($0) }
        let yValues = inputY.split(separator: " ").compactMap { Double($0) }
        
        // Проверяем, что количество X и Y совпадает
        guard xValues.count == yValues.count else {
            errorMessage = "Ошибка: Количество значений X и Y должно совпадать"
            return
        }
        
        // Создаем массив точек
        graphPoints = Array(zip(xValues, yValues))
        approximationPoints = graphPoints
    }
    
    // Функция для аппроксимации
    func calculateApproximation() {
        guard graphPoints.count > 1 else {
            errorMessage = "Ошибка: Недостаточно точек для аппроксимации"
            return
        }
        
        let xValues = graphPoints.map { $0.0 }
        let yValues = graphPoints.map { $0.1 }
        let n = Double(xValues.count)
        
        let sumXValues = xValues.reduce(0, +)
        let sumYValues = yValues.reduce(0, +)
        let sumXYValues = zip(xValues, yValues).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXXValues = xValues.reduce(0) { $0 + $1 * $1 }
        
        let denominator = (n * sumXXValues - sumXValues * sumXValues)
        guard denominator != 0 else {
            errorMessage = "Ошибка: Все точки имеют одинаковое значение X"
            return
        }
        
        let slope = (n * sumXYValues - sumXValues * sumYValues) / denominator
        let intercept = (sumYValues - slope * sumXValues) / n
        
        let minX = xValues.min() ?? 0
        let maxX = xValues.max() ?? 0
        
        // Добавляем больше точек для плавной линии
        approximationPoints = stride(from: minX, through: maxX, by: 0.1).map { x in
            let y = slope * x + intercept
            // Ограничиваем значение Y нулем, если оно отрицательное
            return (x, max(y, 0))
        }
    }
    
    // Функция для удаления графика
    func clearGraph() {
        inputX = ""
        inputY = ""
        graphPoints = []
        approximationPoints = []
        errorMessage = ""
    }
}

// Представление для отображения графика во весь экран
struct FullScreenChartView: View {
    let graphPoints: [(Double, Double)]
    let approximationPoints: [(Double, Double)]
    @Binding var isFullScreen: Bool // Передаем состояние для закрытия модального окна
    
    var body: some View {
        VStack {
            Chart {
                ForEach(Array(graphPoints.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("X", point.0),
                        y: .value("Y", point.1)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                ForEach(Array(approximationPoints.enumerated()), id: \.offset) { index, point in
                    PointMark(
                        x: .value("X", point.0),
                        y: .value("Y", point.1)
                    )
                    .foregroundStyle(Color.red)
                    .symbolSize(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            
            Button("Закрыть") {
                isFullScreen = false // Закрываем модальное окно
            }
            .padding()
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
