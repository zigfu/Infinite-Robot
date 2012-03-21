using UnityEngine;
using System.Collections;

public class toggleOnCollide : MonoBehaviour {

	// Use this for initialization
	void Start () {
		//reportDist.text = "1";
	}
	
	public Transform target;
	public float threshold = .1f;
	public float thresholdOut = .1f;
	public GUIText reportDist;
	public GUIText reportVec;
	bool firing;
	
	public Renderer character;
	public Transform hand;
	public Transform head;
	public Transform headBack;
	public float headBackThreshold = .2f;
	public float headBackHysteris = .1f;
	bool waitForHeadBackExit = false;
	public GameObject sword;
	bool swordOn = false;
	
	public Vector3 offset;
	public GameObject projectile;

	public Transform shoulder;
	public float handShoulderThreshold = .3f;
	
	public float colinearityThreshold = .2f;
	
	public bool untogggleable = true;
	public float timeToFire = 10f;
	public float timeToCoolOff = 2f;
	bool untoggleableNow = true;
	bool reloadableNow = false;
	bool reload = false;
    public Transform spawnAt;
	// Update is called once per frame
	void Update () {
		Vector3 distance = (target.position	- transform.position);
		string f = distance.sqrMagnitude.ToString();
		
	if (!swordOn)
	{	if ((distance.sqrMagnitude < threshold) && (!firing) && (!coolOff))
		{
			untoggleableNow = false;
			firing = true;
			f += " FIRING";
			StartCoroutine("fireRoutine");
		}
		
		if (firing && (distance.sqrMagnitude > (threshold+thresholdOut)))
		{
			untoggleableNow = true;
		}
		
		if ((distance.sqrMagnitude < threshold) && untoggleableNow && untogggleable)
		{
			firing = false;			
		}
	}
	else
	{	firing = false;	
	}		
		Vector3 handToShoulder = shoulder.position - hand.position;
		Vector3 elbowToShoulder = shoulder.position - transform.position;
		Vector3 elbowToHand = hand.position - transform.position;
		
		float handToShoulderDistance = handToShoulder.magnitude;
		float elbowToHandDistance = elbowToHand.magnitude;
		float elbowToShoulderDistance = elbowToShoulder.magnitude;
		
		
		if (!swordOn)
		{
		if (((!firing) || (coolOff)) && (handToShoulder.sqrMagnitude < handShoulderThreshold))
		{
			reloadableNow = true;
		}
		float threshtest = (elbowToHandDistance+elbowToShoulderDistance - handToShoulderDistance);
		reportDist.text = threshtest.ToString();
		
		if ((!firing) && reloadableNow && (threshtest < colinearityThreshold))
		{
			reload = true;
			firing = true;
			StartCoroutine("fireRoutine");
			reloadableNow = false;
		}
		}
	
		//reportDist.text = f;					
		
		
		Vector3 handHeadBack = hand.position - headBack.position;
		if ((transform.position.y > shoulder.position.y) || !character.enabled)
		{			
			if(!character.enabled)
			{
				sword.SetActiveRecursively(false);
				swordOn = false;
			}
            reportVec.text = "elbow UP " + handHeadBack.sqrMagnitude.ToString();	
			if ((handHeadBack.sqrMagnitude < headBackThreshold) && (!waitForHeadBackExit))
			{
                print("Sworded!"); 
				//sword Toggle
				waitForHeadBackExit = true;
				sword.SetActiveRecursively(!swordOn);
				swordOn = !swordOn;				
			}
			//head relative hand position
			
		}
		else
		{
			reportVec.text = "";
		}
		if ((handHeadBack.sqrMagnitude > headBackThreshold+headBackHysteris))
		{
			waitForHeadBackExit = false;
		}
	}
	
	
	bool coolOff = false;
	public float timeBetweenShots = .1f;
	public float velocityScale = 10f;
	public float distOffset = 1.0f;
	public float totalTime = 0f;
	IEnumerator fireRoutine()
	{
		totalTime = 0f;
		while(firing)	
		{
			
			Vector3 direction = (hand.transform.position - transform.position);
            GameObject clone = (GameObject)Instantiate(projectile, spawnAt.position, spawnAt.rotation);
			clone.rigidbody.velocity = spawnAt.forward * velocityScale;
			//reportVec.text = clone.rigidbody.velocity.ToString(); 
			yield return new WaitForSeconds(timeBetweenShots);
			totalTime += timeBetweenShots;
			if ((totalTime > timeToFire) || swordOn || !character.enabled)
			{
				coolOff = true;
				firing = false;
			}
		
		}
		//StartCoroutine("coolDownRoutine");
	}
	/*
	IEnumerator coolDownRoutine()
	{
		totalTime = 0.0f;
		while (totalTime < timeToCoolOff)
		{	
			totalTime += Time.deltaTime;
			if (reload)
			{
				
				firing = true;
				coolOff = false;
				reload = false;
				StartCoroutine("fireRoutine");	
				break;
			}
			yield return new WaitForEndOfFrame();
		}		
		coolOff = false;
	
	}
	*/
	
}
