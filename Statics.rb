# coding: utf-8
class STATICS #シミュレション結果出力クラス
  @@linkLoadAry={}
  @@userReceiveContentAry={ totalTime: 0, contentTime: 0, queryTime: 0, totalNum: 0, }
  @@contentAry = {} # コンテンツごとの統計
  @@routerAry = {}  # ルータごとの統計
  @@userAry = {}    # ユーザごとの統計
  @@serverAry ={}   # サーバごとの統計
  @@resultAry = {}

  def self.Init()
    cInitRouterAry = lambda{ # ルータごとの統計初期化
      ROUTER.GetRouterAry.each{ |nodeId,v| 
        @@routerAry[ nodeId ] = {
          "cacheHitNum" => 0,
          "routerReceiveQuery" => 0,
          "routerReceiveQueryContent" => {},
          "contentIdAry" => {},
        }
      }
    }
    cInitContentAry = lambda{ # コンテンツごとの統計初期化
      CONTENT.GetContentAry.each{| id, content |
        @@contentAry[ id ] = {
          cacheLifeTime: 0,
          cacheCount: 0,
          "routerCacheHit"    => 0,
          "userGenerateQuery" => 0,
          "serverReceiveQuery"=> 0, 
          "deleteCache"       => 0,
          "userReceiveContent"=> 0,
          contentHopCount: 0,
          queryHopCount: 0,
          "routerCacheNum"    => 0,
          "routerCacheHitHop" => 0,
        }
      }
    }
    cInitRouterAry.call
    cInitContentAry.call
  end
  
  def self.ReadLogFile()
    puts "Read " + $gSettingAry[:logFile]
    open( $gSettingAry[:logFile] ){|f|
      f.each{ |line|
        logAry = eval( line.gsub(",\n","") )      
        self.ReadLogAry( logAry )
      }
    }
  end

  # STATICS.ReadLogAry
  def self.ReadLogAry( i )
    case( i[:message] )
      when :userReceiveContent then 
        @@userReceiveContentAry[:totalTime] += i[:time] - i[:querySendTime]
        @@userReceiveContentAry[:queryTime] += i[:contentSendTime] - i[:querySendTime]
        @@userReceiveContentAry[:contentTime] += i[:time] - i[:contentSendTime]
        @@userReceiveContentAry[:totalNum] += 1
        @@contentAry[ i[:contentId] ][ :contentHopCount ] += i[:contentHopCount]
        @@contentAry[ i[:contentId] ][ "userReceiveContent" ] += 1
        @@contentAry[ i[:contentId] ][ :queryHopCount ] += i[:queryHopCount] 
        
      when :serverReceiveQuery then
        @@contentAry[ i[:contentId] ][ "serverReceiveQuery" ] += 1
        @@serverAry[ i[:nodeId] ]["serverCacheHit"] +=1 
      when :routerCacheHit     then
        @@contentAry[ i[:contentId] ][ "routerCacheHit" ] += 1
        if ROUTER.GetRouterAry[ i[ :nodeId ] ][ :hopCountAry ][ i[:serverRouterId] ] == nil # サーバに接続されるルータの場合
          hopCount = 0 + 1
        else # hopCountが設定されている場合
          hopCount = ROUTER.GetRouterAry[ i[ :nodeId ] ][ :hopCountAry ][ i[:serverRouterId] ] + 1
        end
        @@contentAry[ i[:contentId] ][ "routerCacheHitHop" ] += hopCount

        @@routerAry[ i[:nodeId] ][ "cacheHitNum" ] += 1
        if @@routerAry[ i[:nodeId] ][ "contentIdAry" ][ i[:contentId] ] == nil
          @@routerAry[ i[:nodeId] ][ "contentIdAry" ][ i[:contentId] ] = 0
        end
        @@routerAry[ i[:nodeId] ][ "contentIdAry" ][ i[:contentId] ] += 1

      when :userGenerateQuery  then
        serverNodeId = CONTENT.GetContentAry[i[:contentId]][:serverNodeId]

        @@contentAry[ i[:contentId] ][ "userGenerateQuery" ] += 1
        if @@userAry[ i[ :userNodeId ] ]  == nil
          @@userAry[ i[ :userNodeId ] ] = {
            "userGenerateQuery" => 0,            
          }
        end
        @@userAry[ i[ :userNodeId ] ][ "userGenerateQuery" ] += 1        
        if @@serverAry[ serverNodeId ]  == nil
          @@serverAry[ serverNodeId ] = {
            "userGenerateQuery" => 0,            
            "serverCacheHit"    => 0,
          }
        end
        @@serverAry[ serverNodeId ][ "userGenerateQuery" ] += 1
      when :routerDeleteCache then 
        @@contentAry[ i[:contentId] ][ "deleteCache" ] += 1
        @@contentAry[ i[:contentId] ][ :cacheLifeTime ]  += i[ :time ] - i[ :cacheTime ]
        
      when :routerReceiveQuery then
        @@routerAry[ i[:nodeId] ][ "routerReceiveQuery" ] += 1
        @@routerAry[ i[:nodeId] ][ "routerReceiveQueryContent" ][ i[ :contentId ] ] = 0 if @@routerAry[ i[:nodeId] ][ "routerReceiveQueryContent" ][ i[:contentId] ] == nil
        @@routerAry[ i[:nodeId] ][ "routerReceiveQueryContent" ][ i[ :contentId ] ] += 1
        
      when :linkSendQuery   then setQueryLinkLoadAry( i )
      when :linkSendContent then setContentLinkLoadAry( i )
    end
  end

  def self.setQueryLinkLoadAry( log )
    from = log[:nodeId]
    to = log[:nextNodeId]
    @@linkLoadAry[ "#{from}-#{to}" ] = {"packet"=>0} if @@linkLoadAry[ "#{from}-#{to}" ] == nil
    @@linkLoadAry[ "#{from}-#{to}"]["packet"] += log[:queryPacketSize]
  end

  def self.setContentLinkLoadAry( log )
    from = log[:nodeId]
    to = log[:nextNodeId]
    @@linkLoadAry["#{from}-#{to}"] = {"packet"=>0} if @@linkLoadAry["#{from}-#{to}"] == nil
    @@linkLoadAry["#{from}-#{to}"]["packet"] += log[:contentPacketSize]
  end


  def self.SaveRouterReceiveQuery( filePath )
    routerReceiveQueryStr = "R,T,"
    CONTENT.GetContentAry.each{|contentId,content| routerReceiveQueryStr << "#{contentId}," }
    ROUTER.GetRouterAry.each{|routerId,router|
      routerReceiveQueryStr << "#{routerId},#{@@routerAry[routerId]["routerReceiveQuery"]},"
      CONTENT.GetContentAry.each{ | contentId, content | 
        if @@routerAry[ routerId ]["routerReceiveQueryContent"][ contentId ] != nil
          routerReceiveQueryStr << @@routerAry[ routerId ]["routerReceiveQueryContent"][ contentId ].to_s + ","
        else
          routerReceiveQueryStr << ","
        end
      }
      routerReceiveQueryStr << "\n"
    }
    open( filePath ,"w"){ |f| f.write( routerReceiveQueryStr ) }
  end

  def self.SaveRouterCacheHitContent( filePath )
    routerCacheHitContentStr = "R,T,"
    CONTENT.GetContentAry.each{|k,v| routerCacheHitContentStr << "#{k},"}
    ROUTER.GetRouterAry.each{|routerId,router|
      routerCacheHitContentStr << "#{routerId},#{@@routerAry[routerId]["cacheHitNum"]},"
      CONTENT.GetContentAry.each{|contentId,content|
        if @@routerAry[routerId][ "contentIdAry" ][contentId] != nil
          routerCacheHitContentStr << @@routerAry[ routerId] ["contentIdAry"][contentId].to_s + "," 
        else
          routerCacheHitContentStr << ","
        end
      }
      routerCacheHitContentStr << "\n"
    }
    open( filePath , "w"){|f| f.write( routerCacheHitContentStr ) }  

    end
  def self.SaveServerAry( inFilePath )
    outStr = "serverId,userGenerateQuery,serverCacheHit\n"
    outStr << @@serverAry.inject(""){|x,(k,v)| x << "#{k},#{v["userGenerateQuery"]},#{v["serverCacheHit"]}\n" }
    open( inFilePath, "w" ){|f| f.write( outStr )}
  end

  def self.SaveLinkLoadAry( inFilePath )
    outStr = @@linkLoadAry.sort{|(k1,v1),(k2,v2)| v2["packet"]<=>v1["packet"]}.inject(""){|x,(k,v)| x << "#{k},#{v["packet"]}\n" }
    open( inFilePath, "w" ){|f| f.write( outStr )}
  end    
  
  def self.SaveContentAry( inFilePath )
    ROUTER.GetRouterAry.each{ | routerId, router |
      router[ :cacheAry ].map{ |v| v[ :contentId ] }.each{ |cache| 
        @@contentAry[ cache ]["routerCacheNum"] += 1
      }
    }
    ROUTER.GetRouterAry.each{|k,v|
      if ( cacheAry =  v[:cacheAry] ) != nil
        cacheAry.each{|cache|
          cache[ :time ] = $gSettingAry[ :simulationTime ]
          cache[ :message ] = :routerDeleteCache
          STATICS.ReadLogAry( cache )
      }
      end
    }
    outStr = "ContentId,NodeId,RouterCacheHitNum,UserGenerateQuery,CacheHitRatio,RouterCacheNum,CacheLifeTime,DeleteCache,ContentHopCount\n"
    contentSortAry = @@contentAry.sort{|a,b| "#{a[0]}".gsub("C","").to_i<=>"#{b[0]}".gsub("C","").to_i }
    contentSortAry.each{ |contentId,v| 
      nodeId = CONTENT.GetContentAry[ contentId ][:serverNodeId]
      routerCacheHitNum =  v["userGenerateQuery"] - v["serverReceiveQuery"]
      cacheHitRatio = v["userGenerateQuery"] > 0 ? 1.0 * ( v["userGenerateQuery"] - v["serverReceiveQuery"] ) / v["userGenerateQuery"]  : 0 
      contentHopCount = v[:contentHopCount] * 1.0 / v["userGenerateQuery"]
      outStr << "#{contentId},#{nodeId},#{routerCacheHitNum},#{v["userGenerateQuery"]},#{cacheHitRatio},#{v["routerCacheNum"]},#{v[:cacheLifeTime]},#{v["deleteCache"]},#{contentHopCount}\n"
    }
    open( inFilePath ,"w"){|f| f.write( outStr ) }
  end
  
  def self.SaveRouterAry( inFilePath )
    outStr = "routerId,cacheHitNum,routerReceiveQuery\n"
    @@routerAry.sort{|(k1,v1),(k2,v2)|v1["cacheHitNum"]<=>v2["cacheHitNum"]}.each{|k,v| 
      outStr << "#{k},#{v["cacheHitNum"]},#{v["routerReceiveQuery"]}\n" 
    }
    open( inFilePath ,"w"){|f| f.write( outStr ) }
  end

  def self.SaveUserAry( inFilePath )
    outStr = ""  
    @@userAry.each{|k,v| outStr << "#{k},#{v["userGenerateQuery"]}\n" if k != nil }
    open( inFilePath,"w"){|f| f.write( outStr ) }  
  end
  def self.CalcResultAry
    contentSortAry = @@contentAry.sort{|a,b| "#{a[0]}".gsub("C","").to_i<=>"#{b[0]}".gsub("C","").to_i }
    @@resultAry["userGenerateQuery"]      = @@contentAry.inject( 0 ){|x,(k,v)| x += v["userGenerateQuery"] }
    @@resultAry["serverReceiveQuery"]     = @@contentAry.inject( 0 ){|x,(k,v)| x += v["serverReceiveQuery"] }
    @@resultAry["routerCacheHit"]         = @@contentAry.inject( 0 ){|x,(k,v)| x += v["routerCacheHit"] }
    @@resultAry["deleteCache"]            = @@contentAry.inject( 0 ){|x,(k,v)| x += v["deleteCache"] }
    @@resultAry["userReceiveContent"]     = @@contentAry.inject( 0 ){|x,(k,v)| x += v["userReceiveContent"] }
    @@resultAry["maxCacheHit"]            = contentSortAry[ 0  ... $gSettingAry[:routerNum]*$gSettingAry[:routerCacheSize] ].inject(0.0){|x,(k,v)| x +=v["userGenerateQuery"]} / @@resultAry["userReceiveContent"]
    @@resultAry["cacheHitRate"]           = ( @@resultAry["routerCacheHit"] ) * 1.0 / @@resultAry["userGenerateQuery"]
    @@resultAry["loss"]                   = @@resultAry["userGenerateQuery"] - @@resultAry["userReceiveContent"]
    @@resultAry["averageQueryHopCount"]   = @@contentAry.inject( 0 ){|x,(k,v)| x += v[:queryHopCount] }   * 1.0 / @@resultAry["userReceiveContent"]
    @@resultAry["averageContentHopCount"] = @@contentAry.inject( 0 ){|x,(k,v)| x += v[:contentHopCount] } * 1.0 / @@resultAry["userReceiveContent"]
    @@resultAry["totalTime"]              = @@userReceiveContentAry[:totalTime] / @@resultAry["userReceiveContent"] 
    @@resultAry["queryTime"]              = @@userReceiveContentAry[:queryTime] / @@resultAry["userReceiveContent"]
    @@resultAry["contentTime"]            = @@userReceiveContentAry[:contentTime] / @@resultAry["userReceiveContent"]  
  end
  def self.SaveResultAry( inFilePath )
    settingStr = $gSettingAry.inspect.gsub("{","").gsub("}",",").gsub(",",",\n").gsub(" ","").gsub("nil","0")
    print( outStr  = @@resultAry.inspect.gsub("{","").gsub("}",",").gsub(",",",\n") )
    open( inFilePath, "w" ){|f| f.write( "{\n" + settingStr + "\n" + outStr.gsub("NaN","0") + "\n" + "}" ) }    
  end
  def self.SaveLog()
    cMakeFolder = lambda{
      folderName = "#{$gSettingAry[:briteFile].to_s.split(".")[0]}S#{$gSettingAry[:serverNum]}C#{$gSettingAry[:contentNum]}Q#{$gSettingAry[:simulationTime]}s#{$gSettingAry[:seed]}_#{$gSettingAry[:routerType]}"
      return folderName if File.exists?( folderName ) == true
      Dir::mkdir( folderName )
      return folderName
    }
    cGetFilePath = lambda{|inFileTag|
      folderName = cMakeFolder.call
      return "#{folderName}/#{$gSettingAry[:zipf]}_#{inFileTag}.csv"
    }
    cGetFilePath.call( "statics" )
    CalcResultAry()
    SaveResultAry( cGetFilePath.call( "staticsAry" ) )
    SaveLinkLoadAry( cGetFilePath.call( "linkAry" ) )
    SaveContentAry( cGetFilePath.call( "contentAry" ) )
    SaveRouterAry( cGetFilePath.call( "routerAry" ) )
#    SaveRouterReceiveQuery( cGetFilePath.call( "routerReceiveQuery" ) )
#    SaveRouterCacheHitContent( cGetFilePath.call( "routerCacheHitContent" ) )
    SaveServerAry( cGetFilePath.call( "serverAry" ) )
    SaveUserAry( cGetFilePath.call( "userAry" ) )
  end
end
