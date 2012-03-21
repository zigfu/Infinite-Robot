using UnityEngine;
using System.Collections;

public class EnemyType1 : MonoBehaviour {
	//public Vector3 spawnPos;
	//public Vector3 endPos;
	public float speed = 10f;
	public float secondsToHover = 5f;
	public float secondsToExit = 5f;
	
	private Vector3 direction;
	private float secondsToLive;
	private int mState = 0;
	private Vector3 hoverPos;
	
	private float secondsEntering;
	public void SetParams(Vector3 spawnPos, Vector3 endPos, float speed)
	{
		//this.spawnPos = spawnPos;
		//this.endPos = endPos;
		//this.speed = speed;
		hoverPos = endPos;
		
		transform.position = spawnPos;
		direction = (endPos - spawnPos);
		
		secondsEntering = direction.magnitude/this.speed;
		//print("secondsToLive "+secondsToLive+" direction.magnitude "+direction.magnitude+" speed "+speed);
		direction = direction.normalized*this.speed;
		//StartCoroutine("Hover");
		print("!!!");
	}
	
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	public float yScale = 1.0f;
	public float rotationStep = 0.1f;
	private float timeInState = 0.0f;
	void Update () {
		timeInState += Time.deltaTime;
		switch(mState)
		{
		case 0:	// entering 
			transform.Translate(direction*Time.deltaTime);
			if (timeInState	> secondsEntering)
			{
				++mState;
				timeInState = 0.0f;
				print("hovering");
			}
			break;
		case 1:	// hovering
			float y = yScale*Mathf.Cos(Time.timeSinceLevelLoad);
			transform.position = new Vector3(hoverPos.x,hoverPos.y+y,hoverPos.z);
			transform.Rotate(new Vector3(0f,rotationStep,0f));
			if (timeInState	> secondsToHover)
			{
				++mState;
				timeInState = 0.0f;
				direction = Vector3.forward*this.speed;
				print("exiting");
			}
			break;
		case 2:	// exiting
			transform.Translate(direction*Time.deltaTime);
			if (timeInState	> secondsToHover)
			{
				Destroy(gameObject);
				print("enemy self-destruct");
			}
			break;
		}
	}
	
	/*IEnumerator DestroyAfter()
	{
		yield return new WaitForSeconds(secondsToLive);
		++mState;
	}
	
	IEnumerator DestroyAfter()
	{
		yield return new WaitForSeconds(secondsToLive);
		Destroy(gameObject);
		print("enemy self-destruct");
	}*/
}
