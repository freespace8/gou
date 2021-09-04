package gou

import (
	"fmt"
	"os"
	"path"
	"testing"

	"github.com/yaoapp/xun/capsule"
	"github.com/yaoapp/xun/logger"
)

// TestAPIRoot
var TestAPIRoot = "/data/apis"
var TestPLGRoot = "/data/plugins"
var TestModRoot = "/data/models"
var TestDSN = "root:123456@tcp(127.0.0.1:3306)/gou?charset=utf8mb4&parseTime=True&loc=Local"
var TestAESKey = "123456"

func TestMain(m *testing.M) {
	TestAPIRoot = os.Getenv("GOU_TEST_API_ROOT")
	TestModRoot = os.Getenv("GOU_TEST_MOD_ROOT")
	TestPLGRoot = os.Getenv("GOU_TEST_PLG_ROOT")
	TestDSN = os.Getenv("GOU_TEST_DSN")
	TestAESKey = os.Getenv("GOT_TEST_AES_KEY")
	capsule.AddConn("primary", "mysql", TestDSN)

	LoadModel("file://"+path.Join(TestModRoot, "user.json"), "user")
	LoadModel("file://"+path.Join(TestModRoot, "manu.json"), "manu")
	LoadModel("file://"+path.Join(TestModRoot, "address.json"), "address")
	LoadModel("file://"+path.Join(TestModRoot, "role.json"), "role")
	LoadModel("file://"+path.Join(TestModRoot, "friends.json"), "friends")
	LoadModel("file://"+path.Join(TestModRoot, "user_roles.json"), "user_roles")

	LoadPlugin(path.Join(TestPLGRoot, "user"), "user")
	defer SelectPlugin("user").Client.Kill()

	LoadAPI("file://"+path.Join(TestAPIRoot, "user.http.json"), "user")
	LoadAPI("file://"+path.Join(TestAPIRoot, "manu.http.json"), "manu")

	// 数据库连接
	capsule.AddConn("primary", "mysql", TestDSN).SetAsGlobal()
	SetModelLogger(os.Stdout, logger.LevelDebug)

	// 加密密钥
	LoadCrypt(fmt.Sprintf(`{"key":"%s"}`, TestAESKey), "AES")
	LoadCrypt(`{}`, "PASSWORD")

	// // 服务终止时释放资源

	// // 启动服务
	// go func() {
	// 	ServeHTTP(Server{
	// 		Port:   5001,
	// 		Allows: []string{"api.test.com", "bing.test.com"},
	// 	})
	// }()

	// Run test suites
	exitVal := m.Run()

	// 释放资源
	KillPlugins()

	// we can do clean up code here
	os.Exit(exitVal)

}
