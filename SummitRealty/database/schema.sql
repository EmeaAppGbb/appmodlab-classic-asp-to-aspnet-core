-- Summit Realty Group Database Schema
-- Classic ASP Application Database
-- SQL Server 2012 Express

USE master;
GO

-- Create database
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'SummitRealty')
BEGIN
    DROP DATABASE SummitRealty;
END
GO

CREATE DATABASE SummitRealty;
GO

USE SummitRealty;
GO

-- Agents table
CREATE TABLE Agents (
    AgentID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    LicenseNumber NVARCHAR(50) NOT NULL,
    Bio NVARCHAR(MAX),
    PhotoPath NVARCHAR(255),
    HireDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- Properties table
CREATE TABLE Properties (
    PropertyID INT PRIMARY KEY IDENTITY(1,1),
    Address NVARCHAR(255) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    State NVARCHAR(2) NOT NULL,
    ZipCode NVARCHAR(10) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    Bedrooms INT NOT NULL,
    Bathrooms DECIMAL(3,1) NOT NULL,
    SquareFeet INT NOT NULL,
    PropertyType NVARCHAR(50) NOT NULL,
    Description NVARCHAR(MAX),
    ListingDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Active',
    AgentID INT NOT NULL,
    FOREIGN KEY (AgentID) REFERENCES Agents(AgentID)
);

-- Users table (plain text passwords - security anti-pattern)
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(50) NOT NULL,  -- Plain text password!
    Role NVARCHAR(20) NOT NULL,
    AgentID INT NOT NULL,
    LastLogin DATETIME NULL,
    FOREIGN KEY (AgentID) REFERENCES Agents(AgentID)
);

-- Inquiries table
CREATE TABLE Inquiries (
    InquiryID INT PRIMARY KEY IDENTITY(1,1),
    PropertyID INT NULL,
    ClientName NVARCHAR(100) NOT NULL,
    ClientEmail NVARCHAR(100) NOT NULL,
    ClientPhone NVARCHAR(20),
    Message NVARCHAR(MAX) NOT NULL,
    InquiryDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    AgentID INT NOT NULL,
    FOREIGN KEY (PropertyID) REFERENCES Properties(PropertyID),
    FOREIGN KEY (AgentID) REFERENCES Agents(AgentID)
);

-- Appointments table
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PropertyID INT NOT NULL,
    AgentID INT NOT NULL,
    ClientName NVARCHAR(100) NOT NULL,
    ClientEmail NVARCHAR(100) NOT NULL,
    AppointmentDate DATETIME NOT NULL,
    Notes NVARCHAR(MAX),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Scheduled',
    FOREIGN KEY (PropertyID) REFERENCES Properties(PropertyID),
    FOREIGN KEY (AgentID) REFERENCES Agents(AgentID)
);

-- PropertyPhotos table
CREATE TABLE PropertyPhotos (
    PhotoID INT PRIMARY KEY IDENTITY(1,1),
    PropertyID INT NOT NULL,
    FilePath NVARCHAR(255) NOT NULL,
    Caption NVARCHAR(255),
    SortOrder INT NOT NULL DEFAULT 1,
    FOREIGN KEY (PropertyID) REFERENCES Properties(PropertyID)
);

GO

-- Insert Agent Data (10 agents)
INSERT INTO Agents (FirstName, LastName, Email, Phone, LicenseNumber, Bio, PhotoPath, HireDate) VALUES
('Sarah', 'Johnson', 'sarah.johnson@summitrealty.com', '(555) 123-4501', 'CA-RE-12345', 'Sarah has been with Summit Realty for over 15 years, specializing in luxury homes and waterfront properties. Her dedication to client satisfaction has earned her numerous awards.', '/images/agents/sarah.jpg', '2008-03-15'),
('Michael', 'Chen', 'michael.chen@summitrealty.com', '(555) 123-4502', 'CA-RE-23456', 'Michael brings a tech-savvy approach to real estate, leveraging digital marketing and virtual tours to showcase properties. He specializes in first-time homebuyers and condos.', '/images/agents/michael.jpg', '2012-07-22'),
('Jennifer', 'Martinez', 'jennifer.martinez@summitrealty.com', '(555) 123-4503', 'TX-RE-34567', 'With a background in interior design, Jennifer helps clients see the potential in every property. She excels in staging and renovation advice.', '/images/agents/jennifer.jpg', '2010-01-10'),
('David', 'Thompson', 'david.thompson@summitrealty.com', '(555) 123-4504', 'FL-RE-45678', 'David is a third-generation realtor with deep roots in the community. He specializes in commercial properties and investment real estate.', '/images/agents/david.jpg', '2005-09-01'),
('Emily', 'Rodriguez', 'emily.rodriguez@summitrealty.com', '(555) 123-4505', 'NY-RE-56789', 'Emily combines her MBA with real estate expertise to provide clients with comprehensive market analysis and investment strategies.', '/images/agents/emily.jpg', '2015-04-18'),
('Robert', 'Anderson', 'robert.anderson@summitrealty.com', '(555) 123-4506', 'WA-RE-67890', 'Bob Anderson has been in real estate for 25 years and knows every neighborhood inside and out. He specializes in family homes and relocation services.', '/images/agents/robert.jpg', '1998-06-12'),
('Lisa', 'Taylor', 'lisa.taylor@summitrealty.com', '(555) 123-4507', 'CA-RE-78901', 'Lisa is passionate about sustainable living and green homes. She helps environmentally conscious buyers find their perfect eco-friendly property.', '/images/agents/lisa.jpg', '2013-11-05'),
('James', 'Wilson', 'james.wilson@summitrealty.com', '(555) 123-4508', 'TX-RE-89012', 'James specializes in luxury estates and high-end properties. His attention to detail and white-glove service sets him apart.', '/images/agents/james.jpg', '2009-02-28'),
('Amanda', 'Brown', 'amanda.brown@summitrealty.com', '(555) 123-4509', 'FL-RE-90123', 'Amanda works primarily with retirees and empty-nesters looking to downsize. Her patient approach and market knowledge are invaluable.', '/images/agents/amanda.jpg', '2016-08-14'),
('Christopher', 'Lee', 'christopher.lee@summitrealty.com', '(555) 123-4510', 'CA-RE-01234', 'Chris leverages his tech background to provide cutting-edge property analysis and virtual reality tours. He specializes in modern urban living.', '/images/agents/christopher.jpg', '2018-03-20');

GO

-- Insert Property Data (55 properties with variety)
INSERT INTO Properties (Address, City, State, ZipCode, Price, Bedrooms, Bathrooms, SquareFeet, PropertyType, Description, ListingDate, Status, AgentID) VALUES
('123 Ocean View Drive', 'San Diego', 'CA', '92101', 1250000, 4, 3.5, 3200, 'Single Family', 'Stunning oceanfront home with panoramic views. Modern kitchen, master suite with spa bath, and private beach access. Recently renovated with high-end finishes throughout.', '2024-01-15', 'Active', 1),
('456 Downtown Loft #305', 'San Francisco', 'CA', '94102', 875000, 2, 2.0, 1450, 'Condo', 'Luxury high-rise condo in the heart of downtown. Floor-to-ceiling windows, granite countertops, stainless appliances, and amenities include gym, pool, and concierge.', '2024-02-20', 'Active', 2),
('789 Suburban Lane', 'Austin', 'TX', '78701', 485000, 3, 2.5, 2100, 'Single Family', 'Charming family home in desirable neighborhood. Updated kitchen, hardwood floors, large backyard with deck. Near top-rated schools and parks.', '2024-01-10', 'Active', 3),
('321 Waterfront Way', 'Miami', 'FL', '33101', 2150000, 5, 4.5, 4800, 'Single Family', 'Magnificent waterfront estate with boat dock. Gourmet kitchen, wine cellar, home theater, infinity pool. Smart home technology throughout.', '2023-12-05', 'Active', 4),
('654 Park Avenue #12B', 'New York', 'NY', '10022', 3500000, 3, 3.0, 2200, 'Condo', 'Pre-war elegance meets modern luxury. Central Park views, marble baths, chef''s kitchen, formal dining. Doorman building with fitness center.', '2024-01-25', 'Active', 5),
('987 Mountain Ridge Road', 'Seattle', 'WA', '98101', 725000, 4, 3.0, 2800, 'Single Family', 'Contemporary home with mountain and water views. Open floor plan, gourmet kitchen, covered deck, 3-car garage. Energy-efficient construction.', '2024-02-01', 'Active', 6),
('147 Green Hills Court', 'Los Angeles', 'CA', '90001', 1850000, 5, 4.0, 4200, 'Single Family', 'Celebrity neighborhood estate. Pool, spa, outdoor kitchen, home gym, theater room. Completely private and gated.', '2023-11-20', 'Active', 1),
('258 Tech Hub Plaza #1501', 'San Jose', 'CA', '95101', 650000, 2, 2.0, 1200, 'Condo', 'Modern high-tech condo in Silicon Valley. Smart home features, rooftop terrace, EV charging, fiber internet. Walk to major tech campuses.', '2024-02-10', 'Active', 2),
('369 Historic District', 'Dallas', 'TX', '75201', 395000, 3, 2.0, 1850, 'Townhouse', 'Beautifully restored historic townhouse. Original hardwoods, exposed brick, updated kitchen and baths. Private courtyard garden.', '2024-01-18', 'Active', 3),
('741 Beach Boulevard', 'Tampa', 'FL', '33602', 895000, 4, 3.5, 3100, 'Single Family', 'Mediterranean-style home steps from the beach. Tile roof, arched doorways, courtyard, outdoor shower. Perfect for coastal living.', '2023-12-15', 'Active', 4),
('852 Upper East Side #8C', 'New York', 'NY', '10075', 2250000, 2, 2.5, 1800, 'Condo', 'Sophisticated pre-war co-op. High ceilings, crown molding, wood-burning fireplace. Building has gym, storage, and live-in super.', '2024-01-30', 'Active', 5),
('963 Lake Washington Drive', 'Seattle', 'WA', '98112', 1450000, 4, 3.5, 3500, 'Single Family', 'Waterfront home on Lake Washington. Private dock, outdoor living spaces, floor-to-ceiling windows. Completely remodeled in 2022.', '2024-02-05', 'Active', 6),
('159 Sunset Strip', 'Los Angeles', 'CA', '90069', 975000, 3, 2.5, 2400, 'Townhouse', 'Ultra-modern townhouse in prime location. Rooftop deck with city views, two-car garage, designer finishes, near nightlife and dining.', '2023-12-28', 'Active', 7),
('753 Silicon Valley Way', 'Palo Alto', 'CA', '94301', 2750000, 5, 4.5, 4500, 'Single Family', 'Stunning modern estate in prestigious neighborhood. Guest house, pool, spa, outdoor kitchen, wine room. Top-rated schools.', '2024-01-20', 'Active', 2),
('486 River Oaks Boulevard', 'Houston', 'TX', '77019', 1650000, 4, 4.0, 4000, 'Single Family', 'Luxurious estate in exclusive River Oaks. Formal living and dining, butler''s pantry, library, 4-car garage, manicured grounds.', '2023-12-10', 'Active', 8),
('795 Art Deco Drive', 'Miami Beach', 'FL', '33139', 1250000, 3, 3.0, 2600, 'Condo', 'Iconic Art Deco building oceanfront condo. Completely renovated, designer kitchen, spa baths, private beach access, valet parking.', '2024-01-12', 'Active', 4),
('357 Brownstone Row', 'Brooklyn', 'NY', '11201', 1850000, 4, 3.5, 3000, 'Townhouse', 'Classic Brooklyn brownstone fully restored. Original details preserved, modern systems, finished basement, garden, roof deck.', '2024-02-08', 'Active', 5),
('951 Capitol Hill', 'Seattle', 'WA', '98102', 565000, 2, 2.0, 1100, 'Condo', 'Hip Capitol Hill condo in boutique building. Hardwood floors, stainless appliances, in-unit washer/dryer, one parking space.', '2024-01-28', 'Active', 6),
('246 Hollywood Heights', 'Los Angeles', 'CA', '90028', 1125000, 3, 3.0, 2200, 'Single Family', 'Mid-century modern home with Hollywood sign views. Post and beam construction, walls of glass, pool, zen garden, renovated.', '2023-11-15', 'Active', 7),
('681 Marina Boulevard #2301', 'San Francisco', 'CA', '94123', 1450000, 3, 2.5, 1900, 'Condo', 'Spectacular Marina District high-rise. Golden Gate Bridge views, marble baths, chef''s kitchen, 24-hour concierge, guest parking.', '2024-02-15', 'Active', 2),
('135 Lakefront Circle', 'Austin', 'TX', '78746', 895000, 4, 3.0, 2900, 'Single Family', 'Beautiful lakefront home with private dock. Open concept, vaulted ceilings, stone fireplace, screened porch, mature trees.', '2024-01-22', 'Active', 3),
('792 Coral Gables Avenue', 'Miami', 'FL', '33134', 1575000, 4, 4.0, 3800, 'Single Family', 'Mediterranean revival estate in Coral Gables. Barrel tile roof, courtyard pool, summer kitchen, impact windows, circular drive.', '2023-12-20', 'Active', 9),
('468 Tribeca Loft #4B', 'New York', 'NY', '10013', 2850000, 2, 2.0, 2100, 'Condo', 'Converted warehouse loft in Tribeca. Soaring ceilings, exposed brick and beams, chef''s kitchen, spa bath, deeded storage.', '2024-01-08', 'Active', 5),
('579 Queen Anne Hill', 'Seattle', 'WA', '98109', 825000, 3, 2.5, 2300, 'Single Family', 'Charming Craftsman on Queen Anne. Original woodwork, built-ins, updated kitchen and baths, bonus room, garden, garage.', '2024-02-12', 'Active', 6),
('813 Beverly Hills Drive', 'Los Angeles', 'CA', '90210', 4250000, 6, 6.0, 6500, 'Single Family', 'Spectacular Beverly Hills estate. Gated and private, infinity pool, tennis court, wine cellar, theater, guest house, chef''s kitchen.', '2023-11-25', 'Active', 7),
('924 Stanford Avenue', 'Palo Alto', 'CA', '94306', 3150000, 4, 3.5, 3600, 'Single Family', 'Eichler-style mid-century modern. Post and beam, walls of glass, atrium, radiant heat, private yard. Walk to Stanford.', '2024-01-16', 'Active', 1),
('247 Memorial Drive', 'Houston', 'TX', '77007', 725000, 3, 3.0, 2500, 'Townhouse', 'Luxury townhouse in museum district. Gourmet kitchen, rooftop terrace, two-car garage, elevator, high ceilings.', '2024-02-18', 'Active', 8),
('658 South Beach Condo #1205', 'Miami Beach', 'FL', '33139', 975000, 2, 2.5, 1600, 'Condo', 'Beachfront luxury condo. Ocean views, Italian kitchen, marble baths, resort amenities including spa, pools, restaurant.', '2023-12-08', 'Active', 9),
('731 Greenwich Village #3A', 'New York', 'NY', '10012', 1650000, 2, 2.0, 1400, 'Condo', 'Charming Village duplex. Wood-burning fireplace, exposed brick, chef''s kitchen, loft bedroom, outdoor space. Pet-friendly.', '2024-01-26', 'Active', 5),
('892 Fremont Neighborhood', 'Seattle', 'WA', '98103', 685000, 3, 2.5, 2000, 'Single Family', 'Updated Craftsman bungalow in Fremont. Hardwoods, built-ins, modern kitchen, finished basement, fenced yard, garage.', '2024-02-02', 'Active', 6),
('145 Malibu Colony Road', 'Malibu', 'CA', '90265', 5750000, 5, 5.5, 5200, 'Single Family', 'Exclusive Malibu Colony beachfront estate. Direct beach access, infinity pool, cabana, gourmet kitchen, media room, breathtaking views.', '2023-10-15', 'Active', 7),
('276 Tech Campus Drive', 'Sunnyvale', 'CA', '94086', 1450000, 4, 3.0, 2800, 'Single Family', 'Modern home near tech campuses. Solar panels, EV charging, smart home, chef''s kitchen, home office, yard. Energy efficient.', '2024-01-14', 'Active', 2),
('387 Hill Country Ranch', 'Austin', 'TX', '78732', 1250000, 4, 3.5, 3500, 'Single Family', 'Texas Hill Country estate on 5 acres. Hill views, pool, outdoor kitchen, guest casita, workshop, horse facilities possible.', '2023-12-18', 'Active', 3),
('498 Key Biscayne Avenue', 'Key Biscayne', 'FL', '33149', 2450000, 5, 4.5, 4200, 'Single Family', 'Waterfront estate on Key Biscayne. Bay views, boat dock, pool, summer kitchen, impact glass, coral stone exterior.', '2024-01-04', 'Active', 4),
('509 Upper West Side #15E', 'New York', 'NY', '10024', 1950000, 3, 2.5, 1750, 'Condo', 'Pre-war classic six. High ceilings, herringbone floors, renovated kitchen and baths, Central Park views. Full-service building.', '2024-02-14', 'Active', 5),
('610 Ballard Avenue', 'Seattle', 'WA', '98107', 795000, 3, 2.5, 2100, 'Townhouse', 'Modern Ballard townhouse. Open floor plan, chef''s kitchen, rooftop deck, two-car garage. Walk to shops and restaurants.', '2024-01-24', 'Active', 6),
('721 Pacific Palisades Drive', 'Los Angeles', 'CA', '90272', 3250000, 5, 4.5, 4600, 'Single Family', 'Pacific Palisades estate near Riviera Country Club. Ocean views, pool, spa, outdoor kitchen, wine cellar, home gym.', '2023-11-30', 'Active', 7),
('832 Campbell Avenue', 'San Jose', 'CA', '95008', 1850000, 4, 3.5, 3200, 'Single Family', 'Willow Glen charmer completely remodeled. Designer kitchen, spa baths, ADU, pool, mature landscaping. Top schools.', '2024-02-06', 'Active', 2),
('943 Montrose Boulevard', 'Houston', 'TX', '77006', 895000, 3, 3.5, 2700, 'Townhouse', 'Contemporary Montrose townhouse. Floor-to-ceiling windows, European kitchen, rooftop terrace, elevator, two-car garage.', '2024-01-11', 'Active', 8),
('154 Fisher Island Drive', 'Fisher Island', 'FL', '33109', 6500000, 4, 5.0, 4800, 'Condo', 'Ultra-luxury Fisher Island condo. Private island living, ocean views, Italian marble, resort amenities, golf, marina, spa.', '2023-12-22', 'Active', 9),
('265 Soho Loft #5C', 'New York', 'NY', '10013', 2450000, 3, 2.5, 2400, 'Condo', 'Authentic Soho loft. Cast iron building, high ceilings, columns, chef''s kitchen, master suite, washer/dryer, storage.', '2024-01-19', 'Active', 5),
('376 Madison Park', 'Seattle', 'WA', '98112', 1650000, 4, 3.5, 3400, 'Single Family', 'Elegant Madison Park home. Formal living and dining, family room, office, master suite, finished basement, yard, garage.', '2024-02-16', 'Active', 6),
('487 Bel Air Estates', 'Los Angeles', 'CA', '90077', 7250000, 6, 7.0, 7500, 'Single Family', 'Bel Air mega-mansion. Gated estate, city and ocean views, infinity pool, tennis court, guest house, theater, wine cellar, gym.', '2023-10-20', 'Active', 7),
('598 University Avenue', 'Palo Alto', 'CA', '94301', 2250000, 3, 3.0, 2400, 'Townhouse', 'Downtown Palo Alto luxury townhouse. Walk to University Ave shops and dining. Modern finishes, rooftop deck, garage.', '2024-01-09', 'Active', 1),
('609 Westlake Hills', 'Austin', 'TX', '78746', 1575000, 4, 4.0, 3800, 'Single Family', 'Hill Country contemporary with panoramic views. Floor-to-ceiling windows, infinity pool, outdoor living, home office, 3-car garage.', '2023-12-12', 'Active', 3),
('710 Coconut Grove Lane', 'Miami', 'FL', '33133', 1850000, 4, 4.5, 3600, 'Single Family', 'Coconut Grove estate on lush lot. Bay views, pool, koi pond, summer kitchen, impact windows, circular drive, guest suite.', '2024-01-27', 'Active', 4),
('821 Carnegie Hill #10D', 'New York', 'NY', '10128', 3250000, 4, 3.5, 2800, 'Condo', 'Carnegie Hill pre-war co-op. Museum Mile location, high ceilings, library, formal dining, renovated kitchen and baths.', '2024-02-11', 'Active', 5),
('932 Eastlake Avenue', 'Seattle', 'WA', '98109', 925000, 3, 3.0, 2200, 'Townhouse', 'Houseboats and floating homes nearby. Modern townhouse with lake views, rooftop deck, chef''s kitchen, two-car garage.', '2024-01-17', 'Active', 6),
('143 Santa Monica Beach', 'Santa Monica', 'CA', '90401', 2950000, 4, 4.0, 3200, 'Single Family', 'Santa Monica beach house. Steps to sand, ocean views, outdoor shower, landscaped yard, modern kitchen, sustainable features.', '2023-11-18', 'Active', 7),
('254 Cupertino Boulevard', 'Cupertino', 'CA', '95014', 2450000, 5, 4.0, 3900, 'Single Family', 'Luxury home in Cupertino. Top-rated schools, resort yard with pool and spa, gourmet kitchen, office, bonus room, 3-car garage.', '2024-02-03', 'Active', 2),
('365 The Woodlands Circle', 'The Woodlands', 'TX', '77380', 1150000, 5, 4.5, 4200, 'Single Family', 'The Woodlands estate home. Golf course views, chef''s kitchen, study, game room, pool, outdoor kitchen, 3-car garage.', '2024-01-13', 'Active', 8),
('476 Pinecrest Drive', 'Pinecrest', 'FL', '33156', 1750000, 5, 4.0, 4000, 'Single Family', 'Pinecrest family estate on oversized lot. Updated throughout, pool, summer kitchen, hurricane impact glass, circular drive.', '2023-12-26', 'Active', 9),
('587 Financial District #4201', 'New York', 'NY', '10038', 1450000, 2, 2.0, 1500, 'Condo', 'Modern Financial District high-rise. Floor-to-ceiling windows, harbor views, concierge, gym, roof deck, near transit.', '2024-02-09', 'Active', 5),
('698 West Seattle Beach', 'Seattle', 'WA', '98116', 1250000, 4, 3.0, 2900, 'Single Family', 'West Seattle beach house with sound views. Multiple decks, beach access, vaulted ceilings, fireplace, updated kitchen.', '2024-01-21', 'Active', 6),
('709 Echo Park Avenue', 'Los Angeles', 'CA', '90026', 875000, 3, 2.5, 1950, 'Single Family', 'Charming Spanish bungalow in Echo Park. Original details, updated systems, hardwoods, breakfast nook, yard, garage.', '2024-02-17', 'Active', 1);

GO

-- Insert User Data (10 users with plain text passwords - security vulnerability)
INSERT INTO Users (Username, Password, Role, AgentID) VALUES
('admin', 'password123', 'Admin', 1),
('sarah.j', 'welcome1', 'Agent', 1),
('michael.c', 'agent2023', 'Agent', 2),
('jennifer.m', 'realty456', 'Agent', 3),
('david.t', 'summit789', 'Agent', 4),
('emily.r', 'house2024', 'Agent', 5),
('robert.a', 'property1', 'Agent', 6),
('lisa.t', 'green2024', 'Agent', 7),
('james.w', 'luxury999', 'Agent', 8),
('amanda.b', 'retire123', 'Agent', 9);

GO

-- Insert Sample Inquiries (20 inquiries)
INSERT INTO Inquiries (PropertyID, ClientName, ClientEmail, ClientPhone, Message, InquiryDate, Status, AgentID) VALUES
(1, 'John Smith', 'john.smith@email.com', '(555) 111-2222', 'I am interested in viewing this oceanfront property. Please contact me to schedule a showing.', '2024-02-10 14:30:00', 'Contacted', 1),
(2, 'Mary Johnson', 'mary.j@email.com', '(555) 222-3333', 'What are the HOA fees for this condo? Also, is there guest parking available?', '2024-02-12 10:15:00', 'Pending', 2),
(3, 'Robert Williams', 'r.williams@email.com', '(555) 333-4444', 'We would like more information about the schools in this area and schedule a tour.', '2024-02-09 16:45:00', 'Closed', 3),
(5, 'Patricia Brown', 'pat.brown@email.com', '(555) 444-5555', 'Is the seller willing to negotiate on price? We are pre-approved buyers.', '2024-02-14 09:20:00', 'Contacted', 5),
(7, 'James Davis', 'j.davis@email.com', '(555) 555-6666', 'Interested in this property for investment purposes. Can you provide rental history?', '2024-02-11 11:30:00', 'Pending', 1),
(10, 'Linda Miller', 'linda.m@email.com', '(555) 666-7777', 'Beautiful home! When is the earliest we can schedule a viewing?', '2024-02-13 15:00:00', 'Pending', 4),
(15, 'Michael Wilson', 'mike.w@email.com', '(555) 777-8888', 'Does this property include the pool furniture and outdoor kitchen equipment?', '2024-02-08 13:45:00', 'Contacted', 8),
(20, 'Susan Anderson', 'susan.a@email.com', '(555) 888-9999', 'We are relocating from out of state. Can you help with the buying process?', '2024-02-15 10:00:00', 'Pending', 2),
(25, 'Thomas Taylor', 'thomas.t@email.com', '(555) 999-0000', 'Is there room to build an ADU on this property? What are the zoning requirements?', '2024-02-07 14:15:00', 'Closed', 7),
(30, 'Jessica Martinez', 'jessica.m@email.com', '(555) 000-1111', 'Love this mid-century modern! Has the foundation been inspected recently?', '2024-02-16 16:30:00', 'Contacted', 7),
(NULL, 'David Garcia', 'david.g@email.com', '(555) 111-2223', 'I am looking for a 3-bedroom home under $500k. Can you help me find something?', '2024-02-06 12:00:00', 'Pending', 1),
(35, 'Sarah Rodriguez', 'sarah.r@email.com', '(555) 222-3334', 'What is included in the HOA fees for this building?', '2024-02-17 11:00:00', 'Pending', 5),
(40, 'Christopher Lee', 'chris.lee@email.com', '(555) 333-4445', 'Interested in making an offer. Can we schedule a second showing?', '2024-02-05 09:45:00', 'Contacted', 9),
(NULL, 'Karen White', 'karen.w@email.com', '(555) 444-5556', 'We are first-time homebuyers. Do you offer buyer consultation services?', '2024-02-18 14:30:00', 'Pending', 2),
(45, 'Daniel Harris', 'dan.harris@email.com', '(555) 555-6667', 'Can you provide information about property taxes and insurance costs?', '2024-02-04 10:30:00', 'Closed', 1),
(50, 'Elizabeth Clark', 'liz.clark@email.com', '(555) 666-7778', 'This condo is perfect! Are pets allowed in the building?', '2024-02-19 15:45:00', 'Pending', 5),
(12, 'Joseph Lewis', 'joe.lewis@email.com', '(555) 777-8889', 'What are the utility costs for a home this size?', '2024-02-03 13:00:00', 'Contacted', 6),
(8, 'Margaret Walker', 'margaret.w@email.com', '(555) 888-9990', 'Interested in this tech hub location. Is fiber internet available?', '2024-02-20 10:15:00', 'Pending', 2),
(22, 'Brian Hall', 'brian.h@email.com', '(555) 999-0001', 'Can you send me comparable sales in this neighborhood?', '2024-02-02 16:00:00', 'Closed', 3),
(28, 'Nancy Allen', 'nancy.a@email.com', '(555) 000-1112', 'We need to sell our current home first. Do you offer listing services?', '2024-02-21 11:45:00', 'Contacted', 9);

GO

-- Insert Sample Appointments (15 appointments)
INSERT INTO Appointments (PropertyID, AgentID, ClientName, ClientEmail, AppointmentDate, Notes, Status) VALUES
(1, 1, 'John Smith', 'john.smith@email.com', '2024-02-25 14:00:00', 'First showing, client is pre-approved', 'Scheduled'),
(3, 3, 'Robert Williams', 'r.williams@email.com', '2024-02-23 10:00:00', 'Family with two children, interested in school district', 'Scheduled'),
(5, 5, 'Patricia Brown', 'pat.brown@email.com', '2024-02-26 15:30:00', 'Cash buyer, ready to make offer if property meets expectations', 'Scheduled'),
(10, 4, 'Linda Miller', 'linda.m@email.com', '2024-02-24 11:00:00', 'Second showing, bringing contractor', 'Scheduled'),
(15, 8, 'Michael Wilson', 'mike.w@email.com', '2024-02-27 09:00:00', 'Investment buyer, wants to see pool equipment', 'Scheduled'),
(20, 2, 'Susan Anderson', 'susan.a@email.com', '2024-02-28 16:00:00', 'Out-of-state buyer, virtual tour followed by in-person', 'Scheduled'),
(30, 7, 'Jessica Martinez', 'jessica.m@email.com', '2024-03-01 13:00:00', 'Mid-century enthusiast, very interested', 'Scheduled'),
(35, 5, 'Sarah Rodriguez', 'sarah.r@email.com', '2024-02-22 10:30:00', 'HOA questions, wants to meet board if possible', 'Completed'),
(40, 9, 'Christopher Lee', 'chris.lee@email.com', '2024-02-29 14:30:00', 'Second showing, bringing spouse', 'Scheduled'),
(45, 1, 'Daniel Harris', 'dan.harris@email.com', '2024-02-20 15:00:00', 'Needs financing information', 'Completed'),
(50, 5, 'Elizabeth Clark', 'liz.clark@email.com', '2024-03-02 11:30:00', 'Has two dogs, needs to verify pet policy', 'Scheduled'),
(12, 6, 'Joseph Lewis', 'joe.lewis@email.com', '2024-02-21 09:30:00', 'Utility information discussion', 'Completed'),
(2, 2, 'Mary Johnson', 'mary.j@email.com', '2024-03-03 10:00:00', 'HOA and parking questions follow-up', 'Scheduled'),
(7, 1, 'James Davis', 'j.davis@email.com', '2024-02-19 16:30:00', 'Investment analysis discussion', 'Completed'),
(25, 7, 'Thomas Taylor', 'thomas.t@email.com', '2024-02-18 14:00:00', 'ADU zoning consultation', 'Completed');

GO

-- Insert Sample Property Photos
INSERT INTO PropertyPhotos (PropertyID, FilePath, Caption, SortOrder) VALUES
(1, '/images/properties/1_exterior.jpg', 'Front view with ocean backdrop', 1),
(1, '/images/properties/1_kitchen.jpg', 'Gourmet kitchen with island', 2),
(1, '/images/properties/1_master.jpg', 'Master suite with ocean views', 3),
(2, '/images/properties/2_living.jpg', 'Open concept living room', 1),
(2, '/images/properties/2_view.jpg', 'City skyline view from balcony', 2),
(3, '/images/properties/3_exterior.jpg', 'Charming front exterior', 1),
(3, '/images/properties/3_backyard.jpg', 'Large backyard with deck', 2),
(5, '/images/properties/5_exterior.jpg', 'Pre-war building facade', 1),
(5, '/images/properties/5_living.jpg', 'Spacious living room with park views', 2),
(7, '/images/properties/7_pool.jpg', 'Infinity pool overlooking city', 1),
(10, '/images/properties/10_beach.jpg', 'Beach access from backyard', 1),
(15, '/images/properties/15_exterior.jpg', 'Luxury estate entrance', 1),
(20, '/images/properties/20_lobby.jpg', 'Elegant building lobby', 1),
(25, '/images/properties/25_exterior.jpg', 'Beachfront property exterior', 1),
(30, '/images/properties/30_exterior.jpg', 'Mid-century modern architecture', 1);

GO

PRINT 'Summit Realty Database created and seeded successfully!';
PRINT 'Total Agents: 10';
PRINT 'Total Properties: 55';
PRINT 'Total Users: 10 (with plain text passwords)';
PRINT 'Total Inquiries: 20';
PRINT 'Total Appointments: 15';
