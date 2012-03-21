enum eEndPointsMode { AUTO = 0, AUTOCLOSED, EXPLICIT }
enum eWrapMode { ONCE = 0, LOOP }

private var mEndPointsMode = eEndPointsMode.AUTO;

class SplineNode
{
	var Point   : Vector3;
	var Rot     : Quaternion;
	var Time    : float;
	var EaseIO  : Vector2;
	
	function SplineNode(p:Vector3, q:Quaternion, t:float, io:Vector2) { Point=p; Rot=q; Time=t; EaseIO=io; }
	function SplineNode(o : SplineNode) { Point=o.Point; Rot=o.Rot; Time=o.Time; EaseIO=o.EaseIO; }
}

private var mNodes : Array = null;
private var mState : String = "";
private var mRotations : boolean = false;

private var mOnEndCallback:Object;



function Awake()
{
	Reset();
}

function StartInterpolation(endCallback : Object, bRotations : boolean, mode : eWrapMode)
{	
	if (mState != "Reset")
		throw "First reset, add points and then call here";
		
	mState = mode == eWrapMode.ONCE? "Once" : "Loop";
	mRotations = bRotations;
	mOnEndCallback = endCallback;
	
	SetInput();
}

function Reset()
{
	mNodes = new Array();
	mState = "Reset";
	mCurrentIdx = 1;
	mCurrentTime = 0.0;
	mRotations = false;
	mEndPointsMode = eEndPointsMode.AUTO;
}

function AddPoint(pos : Vector3, quat : Quaternion, timeInSeconds : float, easeInOut : Vector2)
{
	if (mState != "Reset")
		throw "Cannot add points after start";
	
	mNodes.push(SplineNode(pos, quat, timeInSeconds, easeInOut));
}


function SetInput()
{	
	if (mNodes.length < 2)
		throw "Invalid number of points";

	if (mRotations)
	{
		for (var c:int = 1; c < mNodes.length; c++)
		{
			// Always interpolate using the shortest path -> Selective negation
			if (Quaternion.Dot(mNodes[c].Rot, mNodes[c-1].Rot) < 0)
			{
				mNodes[c].Rot.x = -mNodes[c].Rot.x;
				mNodes[c].Rot.y = -mNodes[c].Rot.y;
				mNodes[c].Rot.z = -mNodes[c].Rot.z;
				mNodes[c].Rot.w = -mNodes[c].Rot.w;
			}
		}
	}
	
	if (mEndPointsMode == eEndPointsMode.AUTO)
	{
		mNodes.Unshift(mNodes[0]);
		mNodes.push(mNodes[mNodes.length-1]);
	}
	else if (mEndPointsMode == eEndPointsMode.EXPLICIT && (mNodes.length < 4))
		throw "Invalid number of points";
}

function SetExplicitMode() : void
{
	if (mState != "Reset")
		throw "Cannot change mode after start";
		
	mEndPointsMode = eEndPointsMode.EXPLICIT;
}

function SetAutoCloseMode(joiningPointTime : float) : void
{
	if (mState != "Reset")
		throw "Cannot change mode after start";

	mEndPointsMode = eEndPointsMode.AUTOCLOSED;
	
	mNodes.push(new SplineNode(mNodes[0] as SplineNode));
	mNodes[mNodes.length-1].Time = joiningPointTime;

	var vInitDir : Vector3  = (mNodes[1].Point - mNodes[0].Point).normalized;
	var vEndDir  : Vector3  = (mNodes[mNodes.length-2].Point - mNodes[mNodes.length-1].Point).normalized;
	var firstLength : float = (mNodes[1].Point - mNodes[0].Point).magnitude;
	var lastLength  : float = (mNodes[mNodes.length-2].Point - mNodes[mNodes.length-1].Point).magnitude;
	
	var firstNode : SplineNode = new SplineNode(mNodes[0] as SplineNode);
	firstNode.Point = mNodes[0].Point + vEndDir*firstLength;
	
	var lastNode : SplineNode = new SplineNode(mNodes[mNodes.length-1] as SplineNode);
	lastNode.Point = mNodes[0].Point + vInitDir*lastLength;
		
	mNodes.Unshift(firstNode);
	mNodes.push(lastNode);
}

private var mCurrentTime = 0.0;
private var mCurrentIdx = 1;

private var mTimeMultiplier = 1.0;

function SetTimeMultiplier(val:float)
{
	mTimeMultiplier = val;
}

function Update ()
{	
	if (mState == "Reset" || mState == "Stopped" || mNodes.length < 4)
		return;
			
	mCurrentTime += Time.deltaTime*mTimeMultiplier;

	// We advance to next point in the path
	if (mCurrentTime >= mNodes[mCurrentIdx+1].Time)
	{
		if (mCurrentIdx < mNodes.length-3)
		{
			mCurrentIdx++;
		}
		else
		{		
			if (mState != "Loop")
			{
				mState = "Stopped";
				
				// We stop right in the end point
				transform.position = mNodes[mNodes.length-2].Point;
				
				if (mRotations)
					transform.rotation = mNodes[mNodes.length-2].Rot;
				
				// We call back to inform that we are ended
				if (mOnEndCallback != null)
					mOnEndCallback();
			}
			else
			{
				mCurrentIdx = 1;
				mCurrentTime = 0.0;
			}
		}
	}
 	
 	if (mState != "Stopped")
 	{
 		// Calculates the t param between 0 and 1
		var param : float = (mCurrentTime - mNodes[mCurrentIdx].Time) / (mNodes[mCurrentIdx+1].Time - mNodes[mCurrentIdx].Time);                                                                                                                                                                                                                                                                                                                                                
	
		// Smooth the param
		param = MathUtils.Ease(param, mNodes[mCurrentIdx].EaseIO.x, mNodes[mCurrentIdx].EaseIO.y);
		
		transform.position = GetHermiteInternal(mCurrentIdx, param);
	
		if (mRotations)
		{
			transform.rotation = GetSquad(mCurrentIdx, param);
		}
 	}
}

function GetSquad(idxFirstPoint : int, t : float) : Quaternion
{
	var Q0 : Quaternion = mNodes[idxFirstPoint-1].Rot;
	var Q1 : Quaternion = mNodes[idxFirstPoint].Rot;
	var Q2 : Quaternion = mNodes[idxFirstPoint+1].Rot;
	var Q3 : Quaternion = mNodes[idxFirstPoint+2].Rot;
	
	var T1 : Quaternion = MathUtils.GetSquadIntermediate(Q0, Q1, Q2);
	var T2 : Quaternion = MathUtils.GetSquadIntermediate(Q1, Q2, Q3);
	
	return MathUtils.GetQuatSquad(t, Q1, Q2, T1, T2);
}



function GetHermiteInternal(idxFirstPoint : int, t : float) : Vector3
{
	var t2 = t*t; var t3 = t2*t;
	
	var P0 : Vector3 = mNodes[idxFirstPoint-1].Point;
	var P1 : Vector3 = mNodes[idxFirstPoint].Point;
	var P2 : Vector3 = mNodes[idxFirstPoint+1].Point;
	var P3 : Vector3 = mNodes[idxFirstPoint+2].Point;
	
	var tension : float = 0.5;	// 0.5 equivale a catmull-rom
	
	var T1 : Vector3 = tension * (P2 - P0);
	var T2 : Vector3 = tension * (P3 - P1);
	
	var Blend1 : float =  2*t3 - 3*t2 + 1;
	var Blend2 : float = -2*t3 + 3*t2;
	var Blend3 : float =    t3 - 2*t2 + t;
	var Blend4 : float =    t3 -   t2;
	
	return Blend1*P1 + Blend2*P2 + Blend3*T1 + Blend4*T2;
}


function GetHermiteAtTime(timeParam : float) : Vector3
{	
	if (timeParam >= mNodes[mNodes.length-2].Time)
		return mNodes[mNodes.length-2].Point;
	
	for (var c:int = 1; c < mNodes.length-2; c++)
	{
		if (mNodes[c].Time > timeParam)
			break;
	}
	
	var idx:int = c-1;
	var param : float = (timeParam - mNodes[idx].Time) / (mNodes[idx+1].Time - mNodes[idx].Time);                                                                                                                                                                                                                                                                                                                                        
	param = MathUtils.Ease(param, mNodes[idx].EaseIO.x, mNodes[idx].EaseIO.y);
	
	return GetHermiteInternal(idx, param);
}