require 'csv'
require 'date'
class RowVessel
    def initialize(id, latitude, longitude, heading, speed_over_ground, 
        last_ais_updated_at, created_at, updated_at, nav_status_code,  
        vessel_id, course, collection_type, source, need_to_scan)
        @id = id
        @latitude = latitude
        @longitude = longitude
        @heading = heading
        @speed_over_ground = speed_over_ground
        @last_ais_updated_at = last_ais_updated_at
        @created_at = created_at
        @updated_at = updated_at
        @nav_status_code = nav_status_code
        @vessel_id = vessel_id
        @course = course
        @collection_type = collection_type
        @source = source
        @need_to_scan = need_to_scan
    end
    def get_id
        return @id
    end
    def get_latitude
        return @latitude
    end
    def get_longitude
        return @longitude
    end
    def get_last_ais_updated_at
        return @last_ais_updated_at
    end
#To string----------------------------------------------------
    def toS
        puts @id + "\t" + @latitude + "\t" + @longitude + "\t" + @heading +
        "\t" + @speed_over_ground + "\t" + @last_ais_updated_at
    end
#Check day----------------------------------------------------
    def equal_day(day, month, year)
        if (@last_ais_updated_at.slice(0..3).to_i==year) and
            (@last_ais_updated_at.slice(5..6).to_i==month) and 
            (@last_ais_updated_at.slice(8..9).to_i==day)
            return true
        end
        return false 
    end
#Get point----------------------------------------------------
    def get_point
        return Point.new(@latitude.to_f,@longitude.to_f,@last_ais_updated_at)
    end
end


class Vessel
    def initialize
        @list = Array.new
        csv = CSV.foreach('vessel.csv', headers: true) do |row|
            @list.push(RowVessel.new(row[0],row[1].sub!(",","."),row[2].sub!(",","."),row[3],row[4],row[5],row[6],row[7],row[8],row[9],row[10],row[11],row[12],row[13]))
        end
    end
#Print------------------------------------------------------------------
    def printFirst(count = 1)
        for i in 0..count-1 do
            print (i+1).to_s + ".  "
            @list[i].toS
        end
    end

    def printLast(count = 1)
        for i in @list.count-count..@list.count-1 do
            print (i+1).to_s + ".  "
            @list[i].toS
        end
    end
#Count by day------------------------------------------------------
    def countByDay(day, month, year)
        count = 0
        @list.each do |item|
            if item.equal_day(day, month, year)
                count+=1
            end
        end
        return count      
    end
#Sort---------------------------------------------------------------------
    def sort_data_ASC
        return @list.sort_by! {|item| item.get_last_ais_updated_at}
    end
    def sort_data_DESC
        return @list.sort! {|item1, item2| item2.get_last_ais_updated_at<=>item1.get_last_ais_updated_at}
    end
#Group--------------------------------------------------------------------
    def group_by_day
        @list.sort_by! {|item| item.get_last_ais_updated_at}
        a = Array.new
        b = Array.new
        b = [@list[0].get_last_ais_updated_at.slice(0..9),@list[0]]
        for i in 1..@list.length-1
            if @list[i].get_last_ais_updated_at.slice(0..9) == @list[i-1].get_last_ais_updated_at.slice(0..9)
                b.push(@list[i])
            else
                a.push(b)
                b = Array.new
                b = [@list[i].get_last_ais_updated_at.slice(0..9),@list[i]]
            end
        end
        return a
    end

#Save velocity to CSV-----------------------------------------------------
    def save_velocity
        csv = CSV.open("velocity.csv", "wb")
        csv << ["id", "velocity"]
        for i in 0..@list.length-2
            velocity = calculate_velocity(@list[i].get_point, @list[i+1].get_point)
            csv << [@list[i].get_id, velocity]
        end
    end 

#Calculate_velocity-----------------------------------------------
    def calculate_velocity(pre_point, next_point)
        r = 3936 #R = 3936 mile or 6378km
        dLat = degreesToRadians(next_point.latitude- pre_point.latitude)
        dLon = degreesToRadians(next_point.longitude - pre_point.longitude)
        lat1 = degreesToRadians(pre_point.latitude)
        lat2 = degreesToRadians(next_point.latitude)
        a = Math.sin(dLat/2)**2 + Math.sin(dLon/2)**2 * Math.cos(lat1) * Math.cos(lat2)
        s = 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
       
        pre_time = DateTime.parse(pre_point.timestamp)
        next_time = DateTime.parse(next_point.timestamp)
        t = ((next_time - pre_time)*24)
        v = s/t
        if v<0
            return (v*-1).to_s + " mile/hours"
        elsif v==0
            return "0 mile/hours"
        else
            return v.to_s + " mile/hours"
        end
    end
    def degreesToRadians(degrees)
        return degrees * 3.1415926535 / 180
    end
end
#Struct Point-----------------------------------------------
Point = Struct.new(:latitude, :longitude, :timestamp) do
end

#Main-------------------------------------------------------
ves = Vessel.new
puts "Print 5 rows----------------------------------------"
ves.printFirst(5)
ves.printLast(5)

puts "Count number records with by day--------------------"
puts ves.countByDay(23,03,2021)

puts "Sorting data by column last_ais_updated_at----------"
ves.sort_data_ASC
ves.sort_data_DESC

puts "Method calculate velocity---------------------------"
puts ves.calculate_velocity(Point.new(29.75863833,32.55569,"2021-04-06 23:25:25"),Point.new(29.75877167,32.55574333,"2021-04-06 23:34:25"))

puts ves.save_velocity


puts "Group by day---------------------------"
ves = Vessel.new
a = ves.group_by_day
a.each do |item|
    puts "--------------------------" + item[0].to_s + "------------------------------"
    for i in 1..item.length-1
        print item[i].toS
    end
end

