# coding: utf-8
module Router_BC
  def Router_BC_Init
  end

  def Router_BC_ReceiveQuery( inEvent ) 
    router = ROUTER.GetRouterAry[ inEvent[:nodeId] ]
    bc = router[ :bcAry ][ inEvent[ :contentId ] ]
    cRouterDeleteBc = lambda{
      routerDeleteBcAry = {
        :time      => inEvent[:time],
        :message   => :routerDeleteBc,
        :nodeId    => inEvent[:nodeId],
        :contentId => inEvent[:contentId],
      }
      EVENT.Register( routerDeleteBcAry )
    }
    cCacheHitQ = lambda{
      router[:cacheAry].detect{ |i| i[:contentId] == inEvent[:contentId] } != nil
    }
    cCacheHit = lambda{
      inEvent[:message] = :routerCacheHit
      EVENT.Register( inEvent )    
    }
    cInvalidationQ = lambda{
      bc != nil && bc[ :downNodeId ] != nil && inEvent[ :pastNodeId ] == bc[ :downNodeId ]
    }
    cInvalidation = lambda{
      cRouterDeleteBc.call
      if bc[ :upNodeId ] == nil
        ROUTER.Router_IP_ReceiveQuery( inEvent ) 
      else 
        inEvent[:bcFlag] = false
        inEvent[:message] = :linkSendQuery
        inEvent[:nextNodeId] = bc[:upNodeId ]
        EVENT.Register( inEvent )
      end
    }
    cBCGuidanceQ = lambda{
      bc != nil && bc[ :downNodeId ] != nil
    }
    cBCGuidance = lambda{
      inEvent[ :bcFlag ] = true
      inEvent[ :message ] = :linkSendQuery
      inEvent[ :nextNodeId ] = bc[ :downNodeId ]
      EVENT.Register( inEvent )
    }    
    cSendQueryToServerQ = lambda{
      inEvent[ :nodeId ] == inEvent[ :serverRouterId ] && bc == nil && inEvent[ :bcFlag ] == false
    }
    cSendQueryToServer = lambda{
      inEvent[:message] = :linkSendQuery
      inEvent[:nextNodeId] = inEvent[ :serverNodeId ]
      inEvent[:bcFlag] = false      
      EVENT.Register( inEvent )
      return
    }
    cSendQueryToRouterQ = lambda{
      inEvent[ :nodeId ] != inEvent[ :serverRouterId ] && bc == nil && inEvent[ :bcFlag ] == false
    }
    cSendQueryToRouter = lambda{
      inEvent[ :message ] = :linkSendQuery
      inEvent[ :nextNodeId ] = ROUTER.GetRouterAry[ inEvent[:nodeId] ][ :routingTblAry ][ inEvent[ :serverRouterId ] ]
      EVENT.Register( inEvent )    
    }
    cInvalidationPluseQ = lambda{
      inEvent[ :bcFlag ] == true && bc == nil
    }
    cInvalidationPluse = lambda{
      if cSendQueryToServerQ.call
        cSendQueryToServer.call
      else
        inEvent[:bcFlag] = false
        inEvent[:message] = :linkSendQuery
        inEvent[:nextNodeId] = inEvent[:pastNodeId]
        EVENT.Register( inEvent )
      end
    }
    # 実際の処理
    if cCacheHitQ.call
      cCacheHit.call
    elsif cInvalidationQ.call
      cInvalidation.call
    elsif cBCGuidanceQ.call
      cBCGuidance.call
    elsif cSendQueryToServerQ.call
      cSendQueryToServer.call
    elsif cInvalidationPluseQ.call
      cInvalidationPluse.call
    elsif cSendQueryToRouterQ.call
      cSendQueryToRouter.call
    else
      Error( "Router_BC.rb No Route", __LINE__ )
    end
  end

  def Router_BC_ReceiveContent( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[:nodeId] ]
    cSetDownNodeId = lambda{
      downNodeId = router[ :routingTblAry ][ inEvent[ :userRouterId ] ]
      if downNodeId == nil || downNodeId.to_s.index("U") != nil || downNodeId.to_s.index("S") != nil
        return nil
      else
        return downNodeId
      end
    }
    cSetUpNodeId = lambda{
      upNodeId = inEvent[ :pastNodeId ]
      if upNodeId == nil || upNodeId.to_s.index("U") != nil || upNodeId.to_s.index("S") != nil
        return nil
      else
        return upNodeId
      end
    }
    cRouterCreateBc = lambda {||
      bcCreateEvent = { 
        :time       => inEvent[ :time ] + ( inEvent[:contentPacketSize] - 1 ) / $gSettingAry[:linkWidth],
        :message    => :routerCreateBc,
        :nodeId     => inEvent[ :nodeId ], # BC作成するルータを設定
        :contentId  => inEvent[ :contentId ], # BC作成するコンテンツIDを設定
        :upNodeId   => cSetUpNodeId.call, 
        :downNodeId => cSetDownNodeId.call, 
      }
      EVENT.Register( bcCreateEvent ) # 下流ノードIDを設定
    }
    # 実際の処理
    cRouterCreateBc.call
    Router_TERC_ReceiveContent( inEvent )
  end
  def Router_BC_CreateCache( inEvent )
    Router_TERC_CreateCache( inEvent )
  end
  def Router_BC_DeleteCache( inEvent )
    Router_TERC_DeleteCache( inEvent )  
  end
  def Router_BC_CacheHit( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ]
    inEvent[ :message ] = :linkSendContent
    inEvent[ :contentSendTime ] = inEvent[:time]
    inEvent[ :cacheHitNodeId ] = inEvent[ :nodeId ]
    Router_BC_ReceiveContent( inEvent )
  end
  def Router_BC_CreateBc( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ]
    cDeleteBcQ = lambda{
      router[ :bcAry ][ inEvent[:contentId] ] != nil      
    }
    cDeleteBc = lambda{
      deleteBC = router[ :bcAry ][ inEvent[:contentId] ]
      deleteBC[:time] = inEvent[:time]
      deleteBC[:message] = :routerDeleteBc
      EVENT.Run( deleteBC ) # 即実行
    }
    cDeleteBc.call if cDeleteBcQ.call
    ROUTER.GetRouterAry[ inEvent[:nodeId] ][ :bcAry ][ inEvent[:contentId] ] = inEvent
  end

  def Router_BC_DeleteBc( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ]
    router[ :bcAry ][ inEvent[:contentId] ] = nil
  end
  
end
