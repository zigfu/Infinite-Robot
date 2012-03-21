enum eOrientationMode { NODE = 0, TANGENT }

var SplineParent : GameObject;
var Duration : float = 10.0;
var OrientationMode : eOrientationMode = eOrientationMode.NODE;
var WrapMode : eWrapMode = eWrapMode.LOOP;
var AutoStart : boolean = true;
var AutoClose : boolean = true;
var HideOnExecute : boolean = false;

var Speed : float = 1.0;

private var mSplineInterp : SplineInterpolator = null;
private var mTransforms : Array = null;

@script AddComponentMenu("Splines/Spline Controller")

function OnDrawGizmos()
{
	var trans : Array = GetTransforms();
	
	if (trans.length < 2)
		return;

	var interp = new SplineInterpolator();
	SetupSplineInterpolator(interp, trans);

	interp.StartInterpolation(null, false, WrapMode);
	
	var prevPos : Vector3 = trans[0].position;
	for (c=1; c <= 100; c++)
	{
		var currTime:float = c * Duration / 100.0;
		var currPos = interp.GetHermiteAtTime(currTime);
		var mag:float = (currPos-prevPos).magnitude * 2.0;
		Gizmos.color = Color(mag, 0.0, 0.0, 1.0);
		Gizmos.DrawLine(prevPos, currPos);
		prevPos = currPos;
	}
}


function Start()
{
	mSplineInterp = gameObject.AddComponent(SplineInterpolator);
	
	mTransforms = GetTransforms();
	
	if (HideOnExecute)
		DisableTransforms();
	
	if (AutoStart)
		FollowSpline();
}


function SetupSplineInterpolator(interp:SplineInterpolator, trans:Array) : void
{
	interp.Reset();
	
	if (AutoClose)
		var step : float = Duration / trans.length;
	else
		step = Duration / (trans.length-1);
	
	for (var c:int = 0; c < trans.length; c++)
	{
		if (OrientationMode == OrientationMode.NODE)
		{
			interp.AddPoint(trans[c].position, trans[c].rotation, step*c, Vector2(0.0, 1.0));
		}
		else if (OrientationMode == OrientationMode.TANGENT)
		{
			if (c != trans.length-1)
				var rot : Quaternion = Quaternion.LookRotation(trans[c+1].position - trans[c].position, trans[c].up);
			else if (AutoClose)
				rot = Quaternion.LookRotation(trans[0].position - trans[c].position, trans[c].up);
			else
				rot = trans[c].rotation;
				
			interp.AddPoint(trans[c].position, rot, step*c, Vector2(0.0, 1.0));
		}
	}

	if (AutoClose)
		interp.SetAutoCloseMode(step*c);
}


// We need this to sort GameObjects by nameclass NameComparer implements IComparer 
{	function Compare(trA : Object, trB : Object) : int {
		return trA.gameObject.name.CompareTo(trB.gameObject.name);	}}


//
// Returns children transforms already sorted by name
//
function GetTransforms() : Array
{
	var ret : Array = new Array();
	
	if (SplineParent != null)
	{
		// We need to use an ArrayList because there´s not Sort method in Array...
		var tempTransformsArray = new ArrayList();	
		var tempTransforms = SplineParent.GetComponentsInChildren(Transform);
		
		// We need to get rid of the parent, which is also returned by GetComponentsInChildren...
		for (var tr : Transform in tempTransforms)
		{
			if (tr != SplineParent.transform)
				tempTransformsArray.Add(tr);
		}
		
		tempTransformsArray.Sort(new NameComparer());
		ret = Array(tempTransformsArray);
	}
	
	return ret;
}

//
// Disables the spline objects, we generally don't need them because they are just auxiliary
//
function DisableTransforms() : void
{
	if (SplineParent != null)
	{
		SplineParent.SetActiveRecursively(false);
	}
}


//
// Starts the interpolation
//
function FollowSpline()
{	
	if (mTransforms.length > 0)
	{
		SetupSplineInterpolator(mSplineInterp, mTransforms);
		mSplineInterp.StartInterpolation(null, true, WrapMode);
	}
}


function Update()
{
	mSplineInterp.SetTimeMultiplier(Speed);
}