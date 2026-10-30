import Foundation

enum AwakeStatus {
    case asleep, awake, awakeDisplay
}

/// One caffeinate process per "awake" session; its lifetime is the assertion.
final class Keeper {
    private var process: Process?
    private(set) var displayLock = false

    var awake: Bool { process?.isRunning ?? false }

    private func spawn() -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        // -w ties the assertion to our pid, so a crash or kill -9 can't leave the
        // machine permanently awake. -s only matters on AC power and is harmless otherwise.
        process.arguments = [
            displayLock ? "-isd" : "-is",
            "-w", String(ProcessInfo.processInfo.processIdentifier),
        ]
        do {
            try process.run()
        } catch {
            FileHandle.standardError.write("awaker: cannot start caffeinate: \(error)\n".data(using: .utf8)!)
        }
        return process
    }

    private static func stop(_ process: Process?) {
        guard let process, process.isRunning else { return }
        process.terminate()
        // caffeinate exits on SIGTERM right away; the kill is a backstop that must not block the UI.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
    }

    func start() {
        // Spawn before stopping so a flag change never leaves a gap without an assertion.
        let old = process
        process = spawn()
        Self.stop(old)
    }

    func stop() {
        Self.stop(process)
        process = nil
    }

    func toggle() {
        if awake { stop() } else { start() }
    }

    func setDisplayLock(_ on: Bool) {
        displayLock = on
        if awake { start() }
    }

    var status: AwakeStatus {
        guard awake else { return .asleep }
        return displayLock ? .awakeDisplay : .awake
    }
}
