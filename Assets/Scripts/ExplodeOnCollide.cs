using UnityEngine;
using System.Collections;

public class ExplodeOnCollide : MonoBehaviour {
	public GameObject explosionObject;
	public float secondsToLive = 1.0f;
	private GameObject childExplosion;
	private GameObject scoreKeeper;
	void Start()
	{
		scoreKeeper = GameObject.Find("scoreKeeper");
	}

	void OnCollisionEnter(Collision collision) 
	{
		print("collision detected: destroy by !"+collision.gameObject.name);
	    //Destroy (gameObject);
		
		
		GameObject clone = (GameObject)Instantiate(explosionObject,transform.position,Quaternion.identity);
		clone.transform.parent = this.transform;
		childExplosion = clone;
		
		StartCoroutine("DestroyAfter");
	}
	
	IEnumerator DestroyAfter()
	{
		yield return new WaitForSeconds(secondsToLive);
		childExplosion.transform.parent = null;
		ParticleEmitter pe = (ParticleEmitter)childExplosion.GetComponent("ParticleEmitter");
		pe.emit = false;
		
		Destroy(gameObject);
		scoreKeeper.GetComponent<scoreKeeper>().AddScore(100);
		print("enemy self-destruct");
	}
}
