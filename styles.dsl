styles {
    element "Dynamic Element" {
        background #ffffff
    }
    # element <tag> {}
    element "Customer" {
        background #08427B
        color #ffffff
        fontSize 22
        shape Person
    }
    element "External System" {
        background #999999
        color #ffffff
    }
    relationship "Relationship" {
        dashed false
    }
    relationship "Async Request" {
        dashed true
    }
    element "Database" {
        shape Cylinder
    }
}
