import XCTest
import ORSSerial
import Gibby
import GBxCartKit

@objc(GameboyClassicReadROMTests)
fileprivate final class GameboyClassicReadROMTests: XCTestCase {
    private typealias Platform  = GameboyClassic
    private typealias Cartridge = Platform.Cartridge
    private typealias Header    = Cartridge.Header
    
    private private(set) var controller: GBxCartReaderController<Cartridge>!
    
    override func setUp() {
        do {
            if controller == nil {
                controller = try GBxCartSerialPortController.reader(for: Platform.self)
                controller.printStacktrace = false
                controller.printProgress = true
            }
        }
        catch {
            fatalError("GBxCart reader was not found. Please connect it to your computer and try again.")
        }
    }

    func testReadHeader() {
        let expectiation = expectation(description: "Header was read")
        
        var romHeader: Header! {
            didSet {
                XCTAssertNotNil(romHeader)
                
                if let header = romHeader {
                    XCTAssertTrue(romHeader.isLogoValid)
                    
                    print("|-------------------------------------|")
                    print("|  CONFIGURATION: \(header.configuration)")
                    print(header)
                }

                expectiation.fulfill()
            }
        }
        
        controller.readHeader { (header: Header?) in
            romHeader = header
        }
        
        waitForExpectations(timeout: 5)
    }

    func testReadROM() {
        let expectiation = expectation(description: "ROM file was read")
        
        var rom: Cartridge! {
            didSet {
                XCTAssertNotNil(rom)

                if let rom = rom {
                    print(rom)
                    print("MD5:", Data(rom[0..<rom.endIndex]).md5.hexString(separator: "").lowercased())
                    if rom.header.isLogoValid {
                        XCTAssertTrue(rom.header.isLogoValid)
                        print("|-------------------------------------|")
                        print("|  CONFIGURATION: \(rom.header.configuration)")
                        print(rom.header)
                        try! rom.write(to: URL(fileURLWithPath: "/Users/kevin/Desktop/\(rom.header.title).gb"))
                    }
                    else {
                        XCTFail("Invalid ROM header.")
                    }
                }
                
                expectiation.fulfill()
            }
        }

        controller.readCartridge { (cartridge: Cartridge?) in
            rom = cartridge
        }
        
        waitForExpectations(timeout: 60)
    }

    func testReadSaveFile() {
        let expectiation = expectation(description: "ROM file was read")
        
        var saveFile: (Data?, Header?) {
            didSet {
                if case let (saveFile?, header?) = saveFile, saveFile.isEmpty == false {
                    print("SRAM:", saveFile)
                    XCTAssertTrue(header.isLogoValid)
                    print("|-------------------------------------|")
                    print("|  CONFIGURATION: \(header.configuration)")
                    print(header)
                    try! saveFile.write(to: URL(fileURLWithPath: "/Users/kevin/Desktop/\(header.title).sav"))
                }
                else {
                    XCTFail("Invalid save data.")
                }
                
                expectiation.fulfill()
            }
        }
        
        controller.readSaveFile { (data: Data?, header: Header) in
            saveFile = (data, header)
        }
        
        waitForExpectations(timeout: 60)
    }
}
