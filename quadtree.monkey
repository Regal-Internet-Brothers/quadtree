Strict

Public

' Preprocessor related:
'#QUADTREE_MOJO2 = True

#If BRL_GAMETARGET_IMPLEMENTED
	#QUADTREE_GRAPHICS = True
#End

' Imports (Public):
' Nothing so far.

' Imports (Private):
Private

Import brl.pool

' Used for debugging purposes:
#If QUADTREE_GRAPHICS And BRL_GAMETARGET_IMPLEMENTED
	#If Not QUADTREE_MOJO2
		Import mojo.graphics
	#Else
		Import mojo2.graphics
	#End
#End

Import regal.util
Import regal.polygon

Public

' Classes:
Class QuadTree<ItemType> Extends QuadTreeNode<ItemType>
	' Constant variable(s) (Public):
	
	' Defaults:
	Const Default_MaxObjects:Int = 8
	Const Default_MaxLevels:Int = 4
	Const Default_ResponsePoolSize:Int = 1 ' Default_MaxObjects
	
	' Constant variable(s) (Protected):
	Protected
	
	' The first "level" used internally.
	Const InitLevel:Int = 0
	
	Public
	
	' Constructor(s):
	Method New(Bounds:Rect, MaxObjects:Int=Default_MaxObjects, MaxLevels:Int=Default_MaxLevels, ResponsePoolSize:Int=Default_ResponsePoolSize)
		Super.New(Null, InitLevel, Bounds)
		
		ConstructQuadTree(Bounds, MaxObjects, MaxLevels, ResponsePoolSize)
	End
	
	Method New(Width:Float, Height:Float, MaxObjects:Int=Default_MaxObjects, MaxLevels:Int=Default_MaxLevels, X:Float=0.0, Y:Float=0.0, ResponsePoolSize:Int=Default_ResponsePoolSize)
		Super.New(Null, InitLevel, Null)
		
		ConstructQuadTree(Width, Height, MaxObjects, MaxLevels, X, Y, ResponsePoolSize)
	End
	
	Method ConstructQuadTree:QuadTree(MaxObjects:Int=Default_MaxObjects, MaxLevels:Int=Default_MaxLevels, ResponsePoolSize:Int=Default_ResponsePoolSize)
		If (Self.NodePool = Null) Then
			Self.NodePool = New Pool<QuadTreeNode<ItemType>>(MaxLevels*NodeArraySize)
		Endif
		
		If (Self.ResponsePool = Null) Then
			Self.ResponsePool = New Pool<Stack<ItemType>>(ResponsePoolSize)
		Endif
		
		If (Self.Trackers = Null) Then
			Self.Trackers = New Stack<Stack<ItemType>>()
		Endif
		
		Self.MaxObjects = MaxObjects
		Self.MaxLevels = MaxLevels
		
		' Return this object so it may be pooled.
		Return Self
	End
	
	Method ConstructQuadTree:QuadTree(Bounds:Rect, MaxObjects:Int=Default_MaxObjects, MaxLevels:Int=Default_MaxLevels, ResponsePoolSize:Int=Default_ResponsePoolSize)
		' Call the super-class's implementation.
		If (ConstructQuadTreeNode(Null, InitLevel, Bounds) = Null) Then Return Null
		
		' Return this object so it may be pooled.
		Return ConstructQuadTree(MaxObjects, MaxLevels, ResponsePoolSize)
	End
	
	Method ConstructQuadTree:QuadTree(Width:Float, Height:Float, MaxObjects:Int=Default_MaxObjects, MaxLevels:Int=Default_MaxLevels, X:Float=0.0, Y:Float=0.0, ResponsePoolSize:Int=Default_ResponsePoolSize)
		' Call the super-class's initialization command.
		If (ConstructQuadTreeNode(Null, InitLevel, Width, Height, X, Y) = Null) Then Return Null
		
		' Call the main implementation.
		Return ConstructQuadTree(MaxObjects, MaxLevels, ResponsePoolSize) ' ConstructionQuadTree(Self.Bounds)
	End
	
	' Destructor(s):
	Method Free:QuadTreeNode<ItemType>()
		' Set the max number of objects and levels to zero.
		Self.MaxObjects = Default_MaxObjects
		Self.MaxLevels = Default_MaxLevels
		
		' Return this object so it may be pooled.
		Return Super.Free()
	End
	
	' Methods (Public):
	Method Update:Void()
		Clear()
		
		UpdateTrackers()
		
		Return
	End
	
	Method UpdateTrackers:Void()
		If (Trackers = Null Or Trackers.IsEmpty()) Then
			Return
		Endif
		
		For Local OStack:= Eachin Trackers
			For Local O:= Eachin OStack
				Insert(O)
			Next
		Next
		
		Return
	End
	
	Method Track:Bool(Tracker:Stack<ItemType>)
		' Check for errors:
		If (Trackers = Null) Then Return False
		If (Tracker = Null) Then Return False
		
		Trackers.AddLast(Tracker)
		
		' Return the default response.
		Return True
	End
	
	Method StopTracking:Bool(Tracker:Stack<ItemType>)
		' Check for errors:
		If (Trackers = Null) Then Return False
		If (Tracker = Null) Then Return False
		
		Trackers.RemoveEach(Tracker)
		
		' Return the default response.
		Return True
	End
	
	Method Deallocate:Void(CTN:QuadTreeNode<ItemType>, Destruct:Bool=True)
		If (Destruct) Then CTN.Free()
		
		If (NodePool <> Null) Then
			NodePool.Free(CTN)
		Endif
		
		Return
	End
	
	Method Deallocate:Void(ResponseStack:Stack<ItemType>, Clear:Bool=True)
		If (Clear) Then ResponseStack.Clear()
		
		If (ResponsePool <> Null) Then
			ResponsePool.Free(ResponseStack)
		Endif
		
		Return
	End
	
	Method CreateQuadTreeNode:QuadTreeNode<ItemType>(Construct:Bool=True)
		If (NodePool <> Null) Then
			Return NodePool.Allocate()
		Endif
		
		Return Null
	End
	
	Method CreateResponse:Stack<ItemType>()
		If (ResponsePool <> Null) Then
			Return ResponsePool.Allocate()
		Endif
		
		Return Null
	End
	
	#Rem
	Method ObjectEnumerator:IEnumerator<T>()
		Return New QuadTreeEnumerator<T>(Self)
	End
	#End
	
	' Methods (Private):
	Private
	
	' Nothing so far.
	
	Public
	
	' Properties (Public):
	Method MaxObjects:Int() Property
		Return Self._MaxObjects
	End
	
	Method MaxLevels:Int() Property
		Return Self._MaxLevels
	End
	
	' Properties (Protected):
	Protected
	
	Method MaxObjects:Void(Input:Int) Property
		Self._MaxObjects = Input
		
		Return
	End
	
	Method MaxLevels:Void(Input:Int) Property
		Self._MaxLevels = Input
		
		Return
	End
	
	Public
	
	' Fields (Public):
	Field NodePool:Pool<QuadTreeNode<ItemType>>
	Field ResponsePool:Pool<Stack<ItemType>>
	Field Trackers:Stack<Stack<ItemType>>
	
	' Fields (Protected):
	Protected
	
	Field _MaxObjects:Int
	Field _MaxLevels:Int
	
	Public
End

' Used by other nodes and 'QuadTrees';
' provides a basic container framework for the tree.
Class QuadTreeNode<ItemType>
	' Constant variable(s):
	
	' The size of the internal node-array.
	Const NodeArraySize:Int = 4
	
	' Node positions:
	Const NODE_TOP_RIGHT:Int		= 0
	Const NODE_TOP_LEFT:Int			= 1
	Const NODE_BOTTOM_LEFT:Int		= 2
	Const NODE_BOTTOM_RIGHT:Int		= 3
	
	' Directions:
	#Rem
		Const Up:Int = 0
		Const Down:Int = 1
		Const Left:Int = 2
		Const Right:Int = 3
	#End
	
	' Constructor(s):
	Method New(ParentNode:QuadTreeNode, Level:Int, Bounds:Rect)		
		' Call the construction method.
		ConstructQuadTreeNode(ParentNode, Level, Bounds)
	End
	
	Method New(ParentNode:QuadTreeNode, Level:Int, Width:Float, Height:Float, X:Float=0.0, Y:Float=0.0)				
		' Call the construction method.
		ConstructQuadTreeNode(ParentNode, Level, Width, Height, X, Y)
	End
	
	Method ConstructQuadTreeNode:QuadTreeNode()
		If (Self.Objects = Null) Then
			Self.Objects = New Stack<ItemType>()
		Else
			If (Not Self.Objects.IsEmpty()) Then
				Self.Objects.Clear()
			Endif
		Endif
		
		' Return this object so it may be pooled.
		Return Self
	End
	
	Method ConstructQuadTreeNode:QuadTreeNode(ParentNode:QuadTreeNode, Level:Int, Bounds:Rect)
		Self.ParentNode = ParentNode
		
		If (Bounds = Null) Then
			Bounds = New Rect()
		Endif
		
		Self.Level = Level
		Self.Bounds = Bounds
				
		' Call the main constructor, and return its output.
		Return ConstructQuadTreeNode()
	End
	
	Method ConstructQuadTreeNode:QuadTreeNode(ParentNode:QuadTreeNode, Level:Int, Width:Float, Height:Float, X:Float=0.0, Y:Float=0.0)
		If (Self.Bounds = Null) Then
			Self.Bounds = New Rect()
		Endif
		
		Self.Bounds.InitRect(X, Y, Width, Height)
		
		' Call the main constructor, and return its output.
		Return ConstructQuadTreeNode(ParentNode, Level, Self.Bounds)
	End
	
	' Destructor(s):
	Method Free:QuadTreeNode()
		' Set the internal level back to zero.
		Self.Level = 0
		
		' Set the parent node to null.
		Self.ParentNode = Null
		
		If (Self.Objects <> Null) Then
			Self.Objects.Clear()
			'Self.Objects = Null
		Endif
		
		' Deallocate all of the sub-nodes within this node so they may be reused:
		If (NodesAvailable) Then
			For Local Index:Int = 0 Until Self.Nodes.Length()
				Deallocate(Self.Nodes[Index], True); Self.Nodes[Index] = Null
			Next
		Endif
		
		' Reset the bounds:
		If (Self.Bounds <> Null) Then
			Self.Bounds.Reset()
			'Self.Bounds = Null
		Endif
		
		' Return this object so it may be pooled.
		Return Self
	End
	
	Method Reset:QuadTreeNode()
		Return Free()
	End
	
	' Methods (Public):
	Method CreateQuadTreeNode:QuadTreeNode(Construct:Bool=True)
		If (ParentNode <> Null) Then
			Return ParentNode.CreateQuadTreeNode(Construct)
		Endif
		
		Return Null
	End
	
	Method CreateResponse:Stack<ItemType>()
		If (ParentNode <> Null) Then
			Return ParentNode.CreateResponse()
		Endif
		
		Return Null
	End
	
	Method Deallocate:Void(CTN:QuadTreeNode, Destruct:Bool=True)
		If (ParentNode <> Null) Then
			ParentNode.Deallocate(CTN, Destruct)
		Endif
		
		Return
	End
	
	Method Deallocate:Void(ResponseStack:Stack<ItemType>, Clear:Bool=True)
		If (ParentNode <> Null) Then
			ParentNode.Deallocate(ResponseStack, Clear)
		Endif
		
		Return
	End
	
	#If QUADTREE_GRAPHICS
		#If Not QUADTREE_MOJO2
			Method Draw:Void()
		#Else
			Method Draw:Void(graphics:DrawList)
		#End
				If (NodesAvailable) Then
					For Local Index:= 0 Until NodeArraySize
						#If Not QUADTREE_MOJO2
							Nodes[Index].Draw()
						#Else
							Nodes[Index].Draw(graphics)
						#End
					Next
				Endif
				
				graphics.SetAlpha(0.15)
				
				#If Not QUADTREE_MOJO2
					graphics.SetColor(0.0, 205.0, 0.0)
				#Else
					'graphics.SetBlendMode(BlendMode.Multiply)
					graphics.SetColor(0.0, 0.8, 0.0)
				#End
				
				If (Bounds <> Null) Then
					#If Not QUADTREE_MOJO2
						Bounds.Draw()
					#Else
						Bounds.Draw(graphics)
					#End
				Endif
				
				graphics.SetAlpha(1.0)
				
				#If Not QUADTREE_MOJO2
					graphics.SetColor(0.0, 105.0, 205.0)
				#Else
					graphics.SetColor(0.0, 0.4, 0.8)
					'graphics.SetBlendMode(BlendMode.Alpha)
				#End
				
				graphics.DrawRect(Bounds.TopLeftX - 4.0, Bounds.TopLeftY - 4.0, 8.0, 8.0)
				graphics.DrawRect(Bounds.TopRightX - 4.0, Bounds.TopRightY - 4.0, 8.0, 8.0)
				graphics.DrawRect(Bounds.BottomLeftX - 4.0, Bounds.BottomLeftY - 4.0, 8.0, 8.0)
				graphics.DrawRect(Bounds.BottomRightX - 4.0, Bounds.BottomRightY - 4.0, 8.0, 8.0)
				
				#If Not QUADTREE_MOJO2
					graphics.SetColor(255.0, 255.0, 255.0)
				#Else
					graphics.SetColor(1.0, 1.0, 1.0)
					'graphics.SetBlendMode(BlendMode.Alpha)
				#End
				
				Return
			End
	#End
	
	Method Clear:Void()
		' Clear the internal object container.
		Objects.Clear()
		
		If (NodesAvailable) Then
			For Local I:= 0 Until NodeArraySize
				Nodes[I].Clear()
				
				Deallocate(Nodes[I])
				
				Nodes[I] = Null
			Next
		Endif
		
		Return
	End
	
   	Method Insert:Bool(P:ItemType)
		' Check for child nodes:
		If (NodesAvailable) Then
			If (SubInsert(P)) Then
				Return True
			Endif
		Endif
		
		If (Bounds.Intersecting(P)) Then ' Bounds.Contains(P)
			If (Objects.Length > MaxObjects And Level < MaxLevels) Then
				If (Not NodesAvailable) Then
					Split()
				Endif
				
				For Local O:= Eachin Objects
					SubInsert(O)
				Next
				
				SubInsert(P)
				
				' Clear the internal container.
				Objects.Clear()
			Else
				Objects.Push(P)
			Endif
			
			Return True
		Endif
		
		' Return the default response.
		Return False
	End
	
	' This command does not check if valid child-nodes are available.
	' The return value of this command specifies if at
	' least one child-node could house the input.
	Method SubInsert:Bool(P:ItemType)
		Local Response:Bool = False
		
		For Local I:= 0 Until NodeArraySize
			If (Nodes[I].Insert(P)) Then
				Response = True
			Endif
		Next
		
		Return Response
	End
	
	' This will produce a temporary stack of objects,
	' please deallocate it after use, so it may be pooled.
	Method Retrieve:Stack<ItemType>(P:ItemType)
		Local ReturnObjects:= CreateResponse()
		
		Retrieve(P, ReturnObjects)
		
		Return ReturnObjects
	End
	
	Method Retrieve:Void(P:ItemType, ReturnObjects:Stack<ItemType>)
		If (Bounds.Intersecting(P)) Then
			RawRetrieve(P, ReturnObjects)
		Endif
		
		If (NodesAvailable) Then
			For Local I:= 0 Until NodeArraySize
				Local Node:= Nodes[I]
				
				#Rem
					'If (Node.Bounds.Intersecting(P)) Then ' Or Node.Bounds.Contains(P)
					If (Node.Bounds.Intersecting(P)) Then ' Or RecursiveContains(P)
						Node.RawRetrieveRecursive(P, ReturnObjects)
					Endif
				#End
				
				Node.Retrieve(P, ReturnObjects)
			Next
		Endif
		
		Return
	End
	
	Method FindParentNode:QuadTreeNode(P:ItemType)
		If (Contains(P)) Then
			Return Self
		Endif
		
		If (NodesAvailable) Then
			For Local I:= 0 Until NodeArraySize
				Local N:= Nodes[I].FindParentNode(P)
				
				If (N <> Null) Then
					Return N
				Endif
			Next
		Endif
		
		Return Null
	End
	
	Method RawRetrieve:Void(P:ItemType, ReturnObjects:Stack<ItemType>)
		For Local O:= Eachin Objects
			If (P = O) Then
				Continue
			Endif
			
			ReturnObjects.Push(O)
		Next
		
		Return
	End
	
	Method RawRetrieveRecursive:Void(P:ItemType, ReturnObjects:Stack<ItemType>)
		RawRetrieve(P, ReturnObjects)
		
		If (NodesAvailable) Then
			For Local I:= 0 Until NodeArraySize
				Nodes[I].RawRetrieveRecursive(P, ReturnObjects)
			Next
		Endif
		
		Return
	End
	
	Method Contains:Bool(O:ItemType)
		Return Objects.Contains(O)
	End
	
	Method RecursiveContains:Bool(O:ItemType)
		If (ParentNode <> Null And ParentNode.RecursiveContains(O)) Then
			Return True
		Endif
		
		Return Contains(O)
	End
	
	Method Resize:Void(W:Float, H:Float)
		Bounds.Resize(W, H)
		
		Return
	End
	
	Method Resize:Void(W:Float, H:Float, X:Float, Y:Float, Center:Bool=False)
		Bounds.Resize(W, H, X, Y, Center)
		
		Return
	End
	
	' Methods (Private):
	Private
	
	Method Split:Void()
		' Local variable(s):
		Local SubWidth:Int = (Bounds.Width/2)
		Local SubHeight:Int = (Bounds.Height/2)
		
		Local X:Float = Bounds.X
		Local Y:Float = Bounds.Y
		
		Local NextLevel:= (Level+1)
		
		' Split into four nodes:
		Nodes[NODE_TOP_RIGHT] = CreateQuadTreeNode().ConstructQuadTreeNode(Self, NextLevel, SubWidth, SubHeight, X+SubWidth, Y)
		Nodes[NODE_TOP_LEFT] = CreateQuadTreeNode().ConstructQuadTreeNode(Self, NextLevel, SubWidth, SubHeight, X, Y)
		Nodes[NODE_BOTTOM_LEFT] = CreateQuadTreeNode().ConstructQuadTreeNode(Self, NextLevel, SubWidth, SubHeight, X, Y+SubHeight)
		Nodes[NODE_BOTTOM_RIGHT] = CreateQuadTreeNode().ConstructQuadTreeNode(Self, NextLevel, SubWidth, SubHeight, X+SubWidth, Y+SubHeight)
				
		Return
	End
	
	Method FindNode:Int(Node:QuadTreeNode)
		' Check for errors:
		If (Node = Null) Then
			Return -1
		Endif
		
		For Local Index:= 0 Until NodeArraySize
			If (Nodes[Index] = Node) Then
				Return Index
			Endif
		Next
		
		' Return the default response.
		Return -1
	End
	
	Method FindNode:QuadTreeNode(Index:Int, Offset:Int=0)
		' Check for errors:
		If (Not NodesAvailable Or Index > NodeArraySize Or Index < 0) Then
			Return Null
		Endif
		
		' Return the desired node.
		Return Nodes[Index]
	End
	
	Public
	
	' Properties (Public):
	Method ObjectsContained:Int() Property
		Local Found:Int = 0
		
		If (NodesAvailable) Then
			For Local N:= 0 Until NodeArraySize
				Found += Nodes[N].ObjectsContained
			Next
		Endif
		
		Return (Found + Objects.Length)
	End
	
	Method MaxObjects:Int() Property
		If (ParentNode <> Null) Then
			Return ParentNode.MaxObjects
		Endif
		
		Return 0
	End
	
	Method MaxLevels:Int() Property
		If (ParentNode <> Null) Then
			Return ParentNode.MaxLevels
		Endif
		
		Return 0
	End
	
	Method NodesAvailable:Bool() Property
		Return (Nodes[0] <> Null) ' (Nodes.Length > 0)
	End
	
	' Properties (Protected):
	Protected
	
	Method MaxObjects:Void(Input:Int) Property
		' Reserved for 'QuadTree'.
		
		Return
	End
	
	Method MaxLevels:Void(Input:Int) Property
		' Reserved for 'QuadTree'.
		
		Return
	End
	
	Method TopNode:QuadTreeNode() Property
		If (ParentNode = Null) Then
			Return Self
		Endif
		
		Return ParentNode.TopNode
	End
	
	Public
	
	' Fields (Public):
	' Nothing so far.
	
	' Fields (Protected):
	Protected
	
	Field ParentNode:QuadTreeNode
	Field Level:Int
	
	' Collections:
	Field Objects:Stack<ItemType>
	Field Nodes:QuadTreeNode[NodeArraySize]
	
	' Polygon(s):
	
	' The bounds of this node.
	Field Bounds:Rect
	
	Public
End