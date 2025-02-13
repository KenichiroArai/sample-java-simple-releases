package com.example;

public class App {

    /** 名前 */
    private String name;

    public void set(String name) {
        this.name = name;
    }

    public String get(String arg) {
        return String.format("%s, %s!", this.name, arg);
    }

    public static void main(String[] args) {
        System.out.println("Hello, Simple Java Sample!");
        App app = new App();
        app.set("名前の設定");
        System.out.println(app.get("テスト"));
    }
}
