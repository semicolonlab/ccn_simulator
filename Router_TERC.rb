module Router_TERC
  def Router_TERC_Init
  
  end

  def Router_TERC_ReceiveQuery( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[:nodeId] ]
  
    cCacheHitQ = lambda{
      router[:cacheAry].detect{ |i| i[:contentId] == inEvent[:contentId] } != nil
    }
    cCacheHit = lambda{
      inEvent[:message] = :routerCacheHit
      EVENT.Register( inEvent )    
    }

    if cCacheHitQ.call
      cCacheHit.call
    else
      Router_IP_ReceiveQuery( inEvent )
    end
  end

  def Router_TERC_ReceiveContent( inEvent ) 
    router = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ]
    cCreateCache = lambda{
      createCache = {
        :time       => inEvent[ :time ] + ( inEvent[ :contentPacketSize ] - 1 ) / $gSettingAry[ :linkWidth ],
        :message    => :routerCreateCache,
        :nodeId     => inEvent[ :nodeId ],
        :contentId  => inEvent[ :contentId ],
        :refreshCount => 0,
        :cacheTime => inEvent[ :time ] + ( inEvent[ :contentPacketSize ] - 1 ) / $gSettingAry[ :linkWidth ]
      }
      EVENT.Register( createCache )    
    }
    cCreateCache.call
    Router_IP_ReceiveContent( inEvent )
  end

  def Router_TERC_CreateCache( inEvent )
    cacheAry = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ][ :cacheAry ]

    cRefreshCacheQ = lambda{
      cacheAry.map{|v|v[ :contentId ] }.index( inEvent[ :contentId ] ) != nil    
    }
    cRefreshCache = lambda{
      cacheIndex = cacheAry.map{|v| v[ :contentId ] }.index( inEvent[ :contentId ] )
      cacheAry.delete_at( cacheIndex )
      cacheAry.push( inEvent )
    }
    cAddCache = lambda {
      cache = {}
      cache[ :time ] = inEvent[ :time ]
      cache[ :cacheTime ] = inEvent[ :time ]
      cache[ :nodeId ] = inEvent[ :nodeId ]
      cache[ :contentId ] = inEvent[ :contentId ]
      cache[ :refreshCount ] = 0
      cacheAry.push( cache )
    }
    cDeleteCacheQ = lambda{
      if cacheAry.length <= $gSettingAry[ :routerCacheSize ]
        return false
      end
    }
    cDeleteCache = lambda{
      deleteCache = cacheAry[ 0 ]
      deleteCache[ :time ] = inEvent[ :time ]
      deleteCache[ :message ] = :routerDeleteCache
      EVENT.Run( cache )
    }
    cCacheNumCheck = lambda{
      Error("cacheSize", __LINE__) if cacheAry.length > $gSettingAry[:routerCacheSize]
    }
    if cRefreshCacheQ.call
      cRefreshCache.call
    elsif cDeleteCacheQ.call
      cDeleteCache.call
    elsif cAddCacheQ.call
      cAddCache.call
  end

  def Router_TERC_DeleteCache( inEvent )
    
  end
  
  def Router_TERC_CacheHit( inEvent )
    inEvent[:contentSendTime] = inEvent[:time]
    Router_IP_ReceiveContent( inEvent )
  end
  
end