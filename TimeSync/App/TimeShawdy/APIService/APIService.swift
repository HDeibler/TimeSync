




import Foundation

class APIService {
    static let shared = APIService()

    // Loading state change handler
    var onLoadingStateChange: ((Bool) -> Void)?

    private init() {}

    func verifyAPIKey(apiKey: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        setLoading(true)
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/API/create/user/\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            setLoading(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer { self?.setLoading(false) }
            
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network request failed"])))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(UserModel.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func setLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            self.onLoadingStateChange?(isLoading)
        }
    }
}

//Get User Enrollments
extension APIService {
    func fetchEnrollmentsAndAssignments(forUserId userId: Int, completion: @escaping (Result<[Enrollment], Error>) -> Void) {
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/user/\(userId)/enrollments/assignments"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -1, userInfo: nil)))
                return
            }

            do {
                let enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
                completion(.success(enrollments))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}


extension APIService {
    func prioritizeEnrollment(userId: Int, courseId: Int, importance: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/user/\(userId)/enrollments/\(courseId)/prioritize/\(importance)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
   
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")


        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -1, userInfo: nil)))
                return
            }

  
            completion(.success(true))
        }.resume()
    }
}

extension APIService {
    func batchPrioritizeEnrollments(userId: Int, prioritizations: [(courseId: Int, importance: Int)], completion: @escaping (Result<Bool, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var lastError: Error?

        prioritizations.forEach { prioritization in
            dispatchGroup.enter()

     
            print("Prioritizing courseId: \(prioritization.courseId) with importance: \(prioritization.importance)")

           
            prioritizeEnrollment(userId: userId, courseId: prioritization.courseId, importance: prioritization.importance) { result in
                if case .failure(let error) = result {
        
                    lastError = error
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {

            if let error = lastError {
            
                completion(.failure(error))
            } else {
   
                completion(.success(true))
            }
        }
    }
}

//fetch user
extension APIService {
    func fetchUserDataForTest(userId: Int, completion: @escaping (Result<UserModel, Error>) -> Void) {
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/user/\(userId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -2, userInfo: nil)))
                return
            }

            do {
                let userData = try JSONDecoder().decode(UserModel.self, from: data)
                completion(.success(userData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
//fetch courses details
extension APIService {
    func fetchCourseDetails(courseId: Int, completion: @escaping (Result<CourseDetail, Error>) -> Void) {
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/utility/get/course/\(courseId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -1, userInfo: nil)))
                return
            }

            do {
                let courseDetail = try JSONDecoder().decode(CourseDetail.self, from: data)
                completion(.success(courseDetail))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension APIService {
    func updateCourseTime(courseId: Int, day: String, time: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/utility/update/coursetime/\(courseId)/\(day)/\(time)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
   

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -1, userInfo: nil)))
                return
            }

            completion(.success(true))
        }.resume()
    }
}


extension APIService {
    func setUserBlackoutDays(userId: Int, blackoutDays: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let urlString = "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/user/\(userId)/set/blackout/\(blackoutDays)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"


        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(error ?? NSError(domain: "APIService", code: -1, userInfo: nil)))
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
        
                completion(.success(true))
            default:
           
                completion(.failure(NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status code: \(httpResponse.statusCode)"])))
            }
        }.resume()
    }
}



