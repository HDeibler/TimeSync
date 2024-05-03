//
//  ClassView.swift
//  TimeShawdy
//
//  Created by Hunter Deibler on 3/28/24.
//
import SwiftUI
import Foundation


struct ClassBlockView: View {
    @State private var isSettingsPresented = false
    
    var className: String
    var times: String
    var assignmentsThisWeek: Int
    var backgroundColor: Color
    var priority: Int
    
    var body: some View {
        NavigationLink(destination: ClassDetailView(className: className, times: times, assignmentsThisWeek: assignmentsThisWeek, backgroundColor: backgroundColor)) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(className)
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("Times: \(times)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Text("Assignments This Week: \(assignmentsThisWeek)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }.padding()
                    
                    Spacer()
                    
                    Button(action: {
                        isSettingsPresented.toggle()
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.black)
                            .padding(8)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 10)
                    .sheet(isPresented: $isSettingsPresented) {
                        ClassSettingsView()
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
    
    

    
    
    struct ClassSettingsView: View {
        @State private var className: String = ""
        @State private var classColor: Color = .blue
        @State private var classTime: String = ""
        @State private var classPriority: Int = 0
        
        var body: some View {
            VStack {
                TextField("Class Name", text: $className)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                ColorPicker("Class Color", selection: $classColor)
                    .padding()
                
                TextField("Class Time", text: $classTime)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Stepper(value: $classPriority, in: 0...10, label: {
                    Text("Priority: \(classPriority)")
                })
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Class Settings")
        }
    }
    
    struct ClassDetailView: View {
        var className: String
        var times: String
        var assignmentsThisWeek: Int
        var backgroundColor: Color
        
        @Environment(\.presentationMode) var presentationMode // Access to presentation mode
        
        var body: some View {
            VStack(spacing: 20) {
                Text(className)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(20)
                    .shadow(radius: 5)

        
                Spacer()
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                                Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
            }
            )
        }
    }
}
