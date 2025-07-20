# 🧑‍🎓 Student Data Web App: Serverless AWS + CloudFront 🚀

A simple web app that lets users save and view student information using AWS serverless services.

---

## 🏗️ Architecture & Workflow

1. **📦 Amazon S3**
   - Hosts `index.html` and `script.js` as a static website.

2. **🌐 Amazon CloudFront**
   - Serves the S3 content via a CDN (Content Delivery Network) for faster global loading and HTTPS support.

3. **🖥️ Browser**
   - Loads the web page and runs the JavaScript code.

4. **📜 script.js**
   - Sends `GET` and `POST` requests to API Gateway using the JavaScript Fetch/AJAX.

5. **🛡️ API Gateway**
   - Exposes a REST API endpoint that proxies requests to Lambda functions.

6. **🧠 AWS Lambda**
   - One function handles data insertion (`POST`)  
   - Another handles data retrieval (`GET`)  
   - Both interact with DynamoDB.

7. **🗃️ Amazon DynamoDB**
   - Stores student records.

---

## ✅ Benefits of This Serverless Architecture

- **🧰 No servers to manage** — AWS handles all infrastructure tasks like patching and scaling.

- **💸 Cost-effective** — you pay only when your code runs; no idle costs.

- **📈 Automatic scaling** — Lambda and CloudFront scale to meet demand with no manual setup.

- **⚡ Global performance** — CloudFront delivers content from edge locations close to users.

- **🔒 High availability** — AWS services are reliable and durable by design.

- **🛡️ Better security** — clear boundaries between frontend (S3/CloudFront) and backend (API Gateway, Lambda, DynamoDB).

---

## 🛠️ Setup Summary

1. 📁 Upload `index.html` + `script.js` to S3 and enable static hosting.  
2. 🌍 Add CloudFront distribution pointing to S3.  
3. 🗂️ Create a DynamoDB table named `studentData`.  
4. 🧠 Create two Lambda functions (`POST` and `GET`) with permissions for DynamoDB.  
5. 🚪 Create a REST API in API Gateway, with GET/POST methods integrating those Lambdas.  
6. 🔓 Enable CORS and deploy the API to a stage (`prod`).  
7. ✏️ Update `script.js` with the API endpoint URL.  
8. 🧹 Invalidate CloudFront cache as needed.

---

### 🎯 Result

A serverless web app that is:

- **⚡ Fast** and globally accessible  
- **📦 Scalable** without manual intervention  
- **💵 Cost-efficient**, billing only when your code runs  
- **🔐 Secure**, with clear boundaries and HTTPS

---

👨‍💻 Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
📬 Contact me on [LinkedIn](https://www.linkedin.com/in/zoraiz-ahmad-89b40233)