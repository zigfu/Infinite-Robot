using UnityEngine;
using System.Collections;

public class shootOnCollide : MonoBehaviour {

	// Use this for initialization
	void Start () {
		reportDist.text = "1";
	}
	
	public Transform target;
	public float threshold = .1f;
	public GUIText reportDist;
	public GUIText reportVec;
	bool firing;
	
	public Transform shootSource;
	public Vector3 offset;
	public GameObject projectile;
	// Update is called once per frame
	void Update () {
		Vector3 distance = (target.position	- transform.position);
		string f = distance.sqrMagnitude.ToString();
		if ((distance.sqrMagnitude < threshold) && (!firing) && coolOff)
		{
			firing = true;
			f += " FIRING";
			StartCoroutine("fireRoutine");
		}
		else if ((firing) && (distance.sqrMagnitude > threshold))
		{
			firing = false;
		}
		reportDist.text = f;					
	}
	
	
	bool coolOff = true;
	public float timeBetweenShots = 1f;
	public float velocityScale = 10f;
	public float distOffset = 1.0f;
	IEnumerator fireRoutine()
	{
		while(firing)	
		{
			coolOff = false;
			Vector3 direction = (shootSource.transform.position - transform.position);				
			GameObject clone = (GameObject)Instantiate(projectile,shootSource.transform.position+direction.normalized*distOffset,Quaternion.identity);
			clone.rigidbody.velocity = direction.normalized * velocityScale;
			reportVec.text = clone.rigidbody.velocity.ToString();
			yield return new WaitForSeconds(timeBetweenShots);
			coolOff = true;
		}
	}
}
