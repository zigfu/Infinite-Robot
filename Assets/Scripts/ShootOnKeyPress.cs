using UnityEngine;
using System.Collections;

public class ShootOnKeyPress : MonoBehaviour {

	bool firing;
	
	public Vector3 offset;
	public GameObject projectile;
	public KeyCode keyTrigger = KeyCode.Mouse0;
	
	// Update is called once per frame
	void Update () {
		if (Input.GetKeyDown(keyTrigger))
		{
			firing = !firing;
			if (firing)
				StartCoroutine("fireRoutine");
		}
	}

	public float timeBetweenShots = 0.5f;
	public float projectileSpeed = 1f;
	public float distOffset = 1.0f;
	IEnumerator fireRoutine()
	{
		while(firing)	
		{
			Vector3 direction = (transform.position - transform.parent.position).normalized;				
			GameObject clone = (GameObject)Instantiate(projectile,transform.position+direction.normalized*distOffset,Quaternion.identity);
			clone.rigidbody.velocity = direction * projectileSpeed;
			//MoveProjectile script = (MoveProjectile)clone.GetComponent("MoveProjectile");
			//script.SetVelocity(direction * projectileSpeed);
			yield return new WaitForSeconds(timeBetweenShots);
		}
	}
}
